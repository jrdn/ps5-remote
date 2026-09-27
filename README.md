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

## Install

`mise run install` builds `PS5 Remote.app`, copies it to `~/Applications` (or `/Applications` with `mise run install --system`), and launches it as a menu bar app. For development, `mise run run` runs it from the terminal with logs.

On first launch macOS will ask for Input Monitoring, Accessibility, and Automation (System Events) permissions.

The menu bar icon shows ⚠️ if a permission is missing (click the warning in the menu to open the Settings pane). The menu also has **Open Log** (`~/Library/Logs/PS5 Remote.log`) and **Launch at Login**.

## Status

Currently figuring out how to read events off the PS5 controller and log them.

