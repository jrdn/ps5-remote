import Foundation
import IOKit
import IOKit.hid

class PS5Controller {
    private var deviceRef: IOHIDDevice?
    private var manager: IOHIDManager?

    // PS5 controller USB IDs
    private let PS5_VENDOR_ID: Int32 = 0x054C  // Sony
    private let PS5_PRODUCT_ID: Int32 = 0x05C5 // DualSense

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

    init() {
        setupHIDManager()
    }

    private func setupHIDManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeSeizeDevice))
        self.manager = manager

        // Set up matching criteria for PS5 controller
        let matching: [String: Any] = [
            kIOHIDVendorIDKey: PS5_VENDOR_ID,
            kIOHIDProductIDKey: PS5_PRODUCT_ID
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
        let timestamp = Date().formatted(date: .omitted, time: .standard)

        // Ignore zero values on analog inputs to reduce noise
        if (usagePage == GENERIC_DESKTOP_PAGE) && intValue == 0 {
            return
        }

        var description = ""

        if usagePage == BUTTON_USAGE_PAGE {
            if let buttonName = buttonNames[usage] {
                let state = intValue == 1 ? "pressed" : "released"
                description = "Button: \(buttonName) \(state)"
            } else {
                description = "Button \(usage): \(intValue)"
            }
        } else if usagePage == GENERIC_DESKTOP_PAGE {
            if let axisName = axisNames[usage] {
                description = "Analog: \(axisName) = \(intValue)"
            } else {
                description = "Axis 0x\(String(usage, radix: 16)): \(intValue)"
            }
        } else {
            description = "Page 0x\(String(usagePage, radix: 16)) Usage 0x\(String(usage, radix: 16)): \(intValue)"
        }

        print("[\(timestamp)] \(description)")
    }

    func start() {
        print("Starting PS5 controller listener...")
        print("Waiting for PS5 controller to connect...\n")
        CFRunLoopRun()
    }
}

// Entry point
let controller = PS5Controller()
controller.start()
