# PS5 Controller Bindings

## Normal Mode

| Input | Action |
|-------|--------|
| X | Enter |
| Circle | Escape |
| Triangle | Close Tab (Cmd+W) *(Firefox/Chrome/Safari only)* |
| L1 | Previous Tab (Cmd+Shift+[) *(browsers)* / Left Click Hold *(elsewhere)* |
| R1 | Next Tab (Cmd+Shift+]) *(Firefox/Chrome/Safari only)* |
| L2 | Start Dictation (Cmd+Shift+D) |
| Share | Switch Space Left (Ctrl+Left) |
| Options | Switch Space Right (Ctrl+Right) |
| PS | Start Dictation (Cmd+Shift+D) |
| Touchpad | Toggle Mission Control |
| R3 (right stick click) | Toggle Voice Control |
| **D-Pad Left** | Cmd+[ (Ghostty only) |
| **D-Pad Right** | Cmd+] (Ghostty only) |
| **Left Stick Up** | Shift+Up (Emacs) / Cmd+` (Ghostty) |
| **Left Stick Down** | Shift+Down (Emacs) / Cmd+Shift+` (Ghostty) |
| **Left Stick Left** | Shift+Left (Emacs) / Ctrl+Shift+Tab (Ghostty) |
| **Left Stick Right** | Shift+Right (Emacs) / Ctrl+Tab (Ghostty) |

## R2 Modifier Mode (Hold R2)

Holding R2 activates an alternate layer for different actions:

| Input | Action |
|-------|--------|
| Square | Middle Click |
| X | Cmd+Return |
| L1 | Left Click |
| R1 | Right Click |
| Left Stick | Mouse Movement |
| Right Stick | Scroll (vertical and horizontal) |

When R2 is held:
- **Left Stick** moves the mouse continuously
- **Right Stick** scrolls (15Hz throttle for smooth scrolling)
- Other buttons have no action (empty)

## Movement Details

### Mouse Movement (R2 + Left Stick)
- Sensitivity: 0.2x of stick deflection
- Active when stick is outside the 20-point deadzone
- Continuous movement while held

### Scrolling (R2 + Right Stick)
- Sensitivity: 0.03x of stick deflection
- Throttled to 15Hz (every 4th frame) for slower, smoother scrolling
- Active when stick is outside the 20-point deadzone

### Stick Deadzone
- Center 128 ± 20 points (0-255 range)
- Prevents jittery small movements from registering

## App-Specific Bindings

### Ghostty Terminal
- **D-Pad Left/Right**: Tab navigation (Cmd+[/Cmd+])
- **Left Stick Up/Down**: Window cycling (Cmd+\`/Cmd+Shift+\`)
- **Left Stick Left/Right**: Tab switching (Ctrl+Shift+Tab/Ctrl+Tab)

### Emacs
- **Left Stick**: Arrow keys with Shift (for selection)
  - Up: Shift+Up
  - Down: Shift+Down
  - Left: Shift+Left
  - Right: Shift+Right

## Unused Buttons
- Square (normal mode), L3, R3
