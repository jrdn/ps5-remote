import Foundation
import IOKit
import IOKit.hid

struct StandardError: TextOutputStream {
    mutating func write(_ string: String) {
        FileHandle.standardError.write(Data(string.utf8))
    }
}
var standardError = StandardError()

class PS5Controller {
    private var deviceRef: IOHIDDevice?
    private var manager: IOHIDManager?

    // PS5 controller IDs (Sony)
    private let PS5_VENDOR_ID: Int32 = 0x054C
    // Product IDs vary by connection type:
    // 0x05C5 = USB wired
    // 0x0CE6 = Bluetooth wireless
    private let PS5_PRODUCT_IDS: [Int32] = [0x05C5, 0x0CE6]

    // HID Usage Pages and Usages for PS5 buttons
    private let BUTTON_USAGE_PAGE: UInt32 = 0x09  // Button
    private let GENERIC_DESKTOP_PAGE: UInt32 = 0x01

    // Button mappings
    private let buttonNames: [UInt32: String] = [
        0x01: "Square",
        0x02: "X",
        0x03: "Circle",
        0x04: "Triangle",
        0x05: "L1",
        0x06: "R1",
        0x07: "L2",
        0x08: "R2",
        0x09: "Share",
        0x0A: "Options",
        0x0B: "L3",
        0x0C: "R3",
        0x0D: "PS",
        0x0E: "Touchpad"
    ]

    // Analog sticks and triggers
    private let axisNames: [UInt32: String] = [
        0x30: "Left Stick X",
        0x31: "Left Stick Y",
        0x32: "Right Stick X",
        0x35: "Right Stick Y",
        0x33: "L2 Trigger",
        0x34: "R2 Trigger"
    ]

    // D-pad (Hat Switch) - usage 0x39
    private let dpadDirections: [Int: String] = [
        0: "Up",
        2: "Right",
        4: "Down",
        6: "Left",
        8: "Neutral"
    ]

    // Stick deadzone - values within this range of center (128) are ignored
    private let STICK_DEADZONE: Int = 20  // ±20 from center

    // Track stick positions (0-255, center at 128)
    private var leftStickX: Int = 128
    private var leftStickY: Int = 128
    private var rightStickX: Int = 128
    private var rightStickY: Int = 128

    // Track last stick directions for hysteresis (only dispatch on direction change)
    private var lastLeftStickDir: String = "Neutral"
    private var lastRightStickDir: String = "Neutral"

    // Track last processed stick positions for smooth movement
    private var lastProcessedLeftX = 128
    private var lastProcessedLeftY = 128
    private var lastProcessedRightX = 128
    private var lastProcessedRightY = 128

    private var updateTimer: DispatchSourceTimer?
    private let stickLock = NSLock()
    private var cachedLeftStickX = 128
    private var cachedLeftStickY = 128
    private var cachedRightStickX = 128
    private var cachedRightStickY = 128


    init() {
        setupHIDManager()
        startUpdateLoop()
    }

    private func startUpdateLoop() {
        let queue = DispatchQueue(label: "com.ps5remote.update", qos: .userInteractive)
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: 1.0 / 60.0)
        timer.setEventHandler { [weak self] in
            self?.updateMouseAndScroll()
        }
        timer.resume()
        self.updateTimer = timer
    }

    private func updateMouseAndScroll() {
        if !r2Active {
            return
        }

        stickLock.lock()
        let leftX = cachedLeftStickX
        let leftY = cachedLeftStickY
        let rightX = cachedRightStickX
        let rightY = cachedRightStickY
        stickLock.unlock()

        // Send left stick mouse movement continuously when outside deadzone
        if !isStickInDeadzone(leftX) || !isStickInDeadzone(leftY) {
            Actions.moveMouseByStick(x: leftX, y: leftY)
        }

        // Send right stick scrolling continuously when outside deadzone
        if !isStickInDeadzone(rightX) || !isStickInDeadzone(rightY) {
            Actions.scrollByStick(x: rightX, y: rightY)
        }
    }

    private func isStickInDeadzone(_ value: Int) -> Bool {
        let center = 128
        return abs(value - center) < STICK_DEADZONE
    }

    private func stickDirection(x: Int, y: Int) -> String {
        let dx = x - 128
        let dy = y - 128

        // Check if both axes are in deadzone
        if abs(dx) < STICK_DEADZONE && abs(dy) < STICK_DEADZONE {
            return "Neutral"
        }

        // Determine direction based on which axis has larger magnitude
        if abs(dx) >= abs(dy) {
            return dx > 0 ? "Right" : "Left"
        } else {
            return dy > 0 ? "Down" : "Up"
        }
    }

    private func setupHIDManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
        self.manager = manager

        // Set up matching criteria - match Sony vendor ID (covers all variants)
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: PS5_VENDOR_ID
        ]

        let matchingCF = matching as CFDictionary
        IOHIDManagerSetDeviceMatching(manager, matchingCF)

        // Set up callbacks
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        IOHIDManagerRegisterDeviceMatchingCallback(manager, { inContext, inResult, inSender, inDevice in
            guard let context = inContext else { return }
            let controller = Unmanaged<PS5Controller>.fromOpaque(context).takeUnretainedValue()
            controller.deviceConnected(inDevice)
        }, selfPtr)

        IOHIDManagerRegisterDeviceRemovalCallback(manager, { inContext, inResult, inSender, inDevice in
            guard let context = inContext else { return }
            let controller = Unmanaged<PS5Controller>.fromOpaque(context).takeUnretainedValue()
            controller.deviceDisconnected(inDevice)
        }, selfPtr)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
    }

    private func deviceConnected(_ device: IOHIDDevice) {
        print("✓ PS5 Controller connected")
        self.deviceRef = device

        // Register input callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputValueCallback(device, { inContext, inResult, inSender, inValue in
            guard let context = inContext else { return }
            let controller = Unmanaged<PS5Controller>.fromOpaque(context).takeUnretainedValue()
            controller.handleInput(inValue)
        }, selfPtr)

        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    }

    private func deviceDisconnected(_ device: IOHIDDevice) {
        print("✗ PS5 Controller disconnected")
        self.deviceRef = nil
    }

    private func handleInput(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let intValue = IOHIDValueGetIntegerValue(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)

        // Ignore zero values on analog inputs to reduce noise (but not D-pad)
        if (usagePage == GENERIC_DESKTOP_PAGE) && intValue == 0 && usage != 0x39 {
            return
        }

        // Handle button presses and releases
        if usagePage == BUTTON_USAGE_PAGE {
            if let buttonName = buttonNames[usage] {
                // R2 button is the modifier layer toggle
                if buttonName == "R2" {
                    r2Active = intValue == 1
                    return
                }

                // Dispatch on press and release
                if intValue == 1 {
                    dispatch(input: .button(buttonName))
                } else if intValue == 0 {
                    dispatch(input: .buttonReleased(buttonName))
                }
            }
            return
        }

        // Handle D-pad (on state change, not continuously)
        if usagePage == GENERIC_DESKTOP_PAGE && usage == 0x39 {
            if let direction = dpadDirections[Int(intValue)] {
                // Only dispatch non-neutral states
                if direction != "Neutral" {
                    dispatch(input: .dpad(direction))
                }
            }
            return
        }


        // Handle analog sticks
        if usagePage == GENERIC_DESKTOP_PAGE {
            // Left stick (usage 0x30=X, 0x31=Y)
            if usage == 0x30 || usage == 0x31 {
                let stickValue = Int(intValue)
                if usage == 0x30 {
                    leftStickX = stickValue
                    stickLock.lock()
                    cachedLeftStickX = stickValue
                    stickLock.unlock()
                } else {
                    leftStickY = stickValue
                    stickLock.lock()
                    cachedLeftStickY = stickValue
                    stickLock.unlock()
                }

                // In normal mode: dispatch directional events on direction change
                if !r2Active {
                    let dir = stickDirection(x: leftStickX, y: leftStickY)
                    if dir != lastLeftStickDir {
                        lastLeftStickDir = dir
                        if dir != "Neutral" {
                            dispatch(input: .leftStick(dir))
                        }
                    }
                }
                return
            }

            // Right stick (usage 0x32=X, 0x35=Y)
            if usage == 0x32 || usage == 0x35 {
                let stickValue = Int(intValue)
                if usage == 0x32 {
                    rightStickX = stickValue
                    stickLock.lock()
                    cachedRightStickX = stickValue
                    stickLock.unlock()
                } else {
                    rightStickY = stickValue
                    stickLock.lock()
                    cachedRightStickY = stickValue
                    stickLock.unlock()
                }

                // In normal mode: dispatch directional events on direction change
                if !r2Active {
                    let dir = stickDirection(x: rightStickX, y: rightStickY)
                    if dir != lastRightStickDir {
                        lastRightStickDir = dir
                        if dir != "Neutral" {
                            dispatch(input: .rightStick(dir))
                        }
                    }
                }
                return
            }
        }
    }

    func start() {
        print("Starting PS5 controller listener...", to: &standardError)
        print("Waiting for PS5 controller to connect...", to: &standardError)
        print("(Vendor ID: 0x\(String(PS5_VENDOR_ID, radix: 16).uppercased()))\n", to: &standardError)
        CFRunLoopRun()
    }
}
