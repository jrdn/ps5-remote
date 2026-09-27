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

    private let PS5_VENDOR_ID: Int32 = 0x054C
    // 0x05C5 = USB wired, 0x0CE6 = Bluetooth
    private let PS5_PRODUCT_IDS: [Int32] = [0x05C5, 0x0CE6]

    private let BUTTON_USAGE_PAGE: UInt32 = 0x09
    private let GENERIC_DESKTOP_PAGE: UInt32 = 0x01

    private let buttonMap: [UInt32: Button] = [
        0x01: .square,
        0x02: .cross,
        0x03: .circle,
        0x04: .triangle,
        0x05: .l1,
        0x06: .r1,
        0x07: .l2,
        0x08: .r2,
        0x09: .share,
        0x0A: .options,
        0x0B: .l3,
        0x0C: .r3,
        0x0D: .ps,
        0x0E: .touchpad,
    ]

    // Hat switch reports 0/2/4/6 for cardinal directions, 8 for neutral
    private let dpadMap: [Int: StickDirection] = [
        0: .up,
        2: .right,
        4: .down,
        6: .left,
    ]

    private let STICK_DEADZONE: Int = 20

    // Stick state — written on main RunLoop thread, read on timer thread; protected by stickLock
    private let stickLock = NSLock()
    private var leftStickX = 128
    private var leftStickY = 128
    private var rightStickX = 128
    private var rightStickY = 128

    // Direction hysteresis — main RunLoop thread only, no lock needed
    private var lastLeftStickDir: StickDirection? = nil
    private var lastRightStickDir: StickDirection? = nil

    private var updateTimer: DispatchSourceTimer?

    var onConnectionChange: ((Bool) -> Void)?

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

    // Runs on timer thread — all shared state accessed under stickLock
    private func updateMouseAndScroll() {
        stickLock.lock()
        let leftX = leftStickX
        let leftY = leftStickY
        let rightX = rightStickX
        let rightY = rightStickY
        stickLock.unlock()

        let modes = currentStickModes()
        applyStickMode(modes.left, x: leftX, y: leftY)
        applyStickMode(modes.right, x: rightX, y: rightY)
    }

    private func applyStickMode(_ mode: StickMode, x: Int, y: Int) {
        guard !isStickInDeadzone(x) || !isStickInDeadzone(y) else { return }
        switch mode {
        case .mouse:      Actions.moveMouseByStick(x: x, y: y)
        case .scroll:     Actions.scrollByStick(x: x, y: y)
        case .directions: break
        }
    }

    private func isStickInDeadzone(_ value: Int) -> Bool {
        abs(value - 128) < STICK_DEADZONE
    }

    private func stickDirection(x: Int, y: Int) -> StickDirection? {
        let dx = x - 128
        let dy = y - 128
        guard abs(dx) >= STICK_DEADZONE || abs(dy) >= STICK_DEADZONE else { return nil }
        if abs(dx) >= abs(dy) {
            return dx > 0 ? .right : .left
        } else {
            return dy > 0 ? .down : .up
        }
    }

    private func setupHIDManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
        self.manager = manager

        // Match each PS5 product ID explicitly to avoid seizing unrelated Sony devices
        let matchingArray = PS5_PRODUCT_IDS.map { pid in
            [kIOHIDVendorIDKey: PS5_VENDOR_ID, kIOHIDProductIDKey: pid] as [String: Any]
        }
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingArray as CFArray)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        IOHIDManagerRegisterDeviceMatchingCallback(manager, { inContext, inResult, inSender, inDevice in
            guard let context = inContext else { return }
            Unmanaged<PS5Controller>.fromOpaque(context).takeUnretainedValue().deviceConnected(inDevice)
        }, selfPtr)

        IOHIDManagerRegisterDeviceRemovalCallback(manager, { inContext, inResult, inSender, inDevice in
            guard let context = inContext else { return }
            Unmanaged<PS5Controller>.fromOpaque(context).takeUnretainedValue().deviceDisconnected(inDevice)
        }, selfPtr)

        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
    }

    private func deviceConnected(_ device: IOHIDDevice) {
        print("✓ PS5 Controller connected")
        self.deviceRef = device
        onConnectionChange?(true)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputValueCallback(device, { inContext, inResult, inSender, inValue in
            guard let context = inContext else { return }
            Unmanaged<PS5Controller>.fromOpaque(context).takeUnretainedValue().handleInput(inValue)
        }, selfPtr)

        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue)
    }

    private func deviceDisconnected(_ device: IOHIDDevice) {
        print("✗ PS5 Controller disconnected")
        self.deviceRef = nil

        // No more input will arrive, so clear held state or the mouse keeps drifting and held keys stay down
        stickLock.lock()
        leftStickX = 128; leftStickY = 128
        rightStickX = 128; rightStickY = 128
        stickLock.unlock()
        lastLeftStickDir = nil
        lastRightStickDir = nil
        releaseAllHeld()
        onConnectionChange?(false)
    }

    // Runs on main RunLoop thread — stick values written here, read on timer thread via stickLock
    private func handleInput(_ value: IOHIDValue) {
        let element = IOHIDValueGetElement(value)
        let intValue = IOHIDValueGetIntegerValue(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)

        if debugMode {
            print("HID page=0x\(String(usagePage, radix: 16)) usage=0x\(String(usage, radix: 16)) value=\(intValue)")
        }

        // Ignore zero values on analog inputs to reduce noise (D-pad excluded)
        if usagePage == GENERIC_DESKTOP_PAGE && intValue == 0 && usage != 0x39 {
            return
        }

        if usagePage == BUTTON_USAGE_PAGE {
            guard let button = buttonMap[usage] else { return }
            dispatch(input: intValue == 1 ? .button(button) : .buttonReleased(button))
            return
        }

        if usagePage == GENERIC_DESKTOP_PAGE && usage == 0x39 {
            if let direction = dpadMap[Int(intValue)] {
                dispatch(input: .dpad(direction))
            }
            return
        }

        if usagePage == GENERIC_DESKTOP_PAGE {
            // Left stick: X=0x30, Y=0x31
            if usage == 0x30 || usage == 0x31 {
                let stickValue = Int(intValue)
                stickLock.lock()
                if usage == 0x30 { leftStickX = stickValue } else { leftStickY = stickValue }
                stickLock.unlock()

                if currentStickModes().left == .directions {
                    let x = usage == 0x30 ? stickValue : leftStickX
                    let y = usage == 0x31 ? stickValue : leftStickY
                    let dir = stickDirection(x: x, y: y)
                    if dir != lastLeftStickDir {
                        lastLeftStickDir = dir
                        if let d = dir { dispatch(input: .leftStick(d)) }
                    }
                }
                return
            }

            // Right stick: X=0x32, Y=0x35
            if usage == 0x32 || usage == 0x35 {
                let stickValue = Int(intValue)
                stickLock.lock()
                if usage == 0x32 { rightStickX = stickValue } else { rightStickY = stickValue }
                stickLock.unlock()

                if currentStickModes().right == .directions {
                    let x = usage == 0x32 ? stickValue : rightStickX
                    let y = usage == 0x35 ? stickValue : rightStickY
                    let dir = stickDirection(x: x, y: y)
                    if dir != lastRightStickDir {
                        lastRightStickDir = dir
                        if let d = dir { dispatch(input: .rightStick(d)) }
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
    }
}
