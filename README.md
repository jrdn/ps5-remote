# ps5-remote

A macOS utility to control your Mac using a PS5 (DualSense) controller.

## Vision

Map PS5 controller buttons and triggers to macOS actions:
- Switch between virtual spaces (Mission Control)
- Switch between windows and applications
- Trigger virtual keyboard events
- Support custom button mappings

## Tech Stack

- **Swift** - Native macOS integration via AppKit, IOKit, and CoreGraphics
- **IOKit** - Read HID events from the PS5 controller
- **AppKit** - Window and space management
- **CoreGraphics** - Synthesize keyboard events

## Status

Currently figuring out how to read events off the PS5 controller and log them.

