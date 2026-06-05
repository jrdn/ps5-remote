# PS5 Controller Bindings

## Normal Mode

| Input | Action |
|-------|--------|
| X | Enter / Backslash *(Lightroom)* |
| Circle | Backspace |
| Square | Cmd+D hold *(Claude)* / Ctrl+M hold *(Codex)* / Space hold *(browsers)* / X key *(Lightroom)* |
| Triangle | Close Tab Cmd+W *(browsers)* / Cmd+Shift+A *(Slack)* / Z key *(Lightroom)* |
| L1 | Prev Tab *(browsers, Claude, Codex)* / Window Cycle Back *(Ghostty/iTerm2)* / Opt+Up *(Slack)* / Space hold *(Lightroom)* |
| R1 | Next Tab *(browsers, Claude, Codex)* / Window Cycle Forward *(Ghostty/iTerm2)* / Opt+Down *(Slack)* |
| L2 | Toggle Dictation (press = on, release = off) |
| L3 (left stick click) | Raycast app switcher (Ctrl+Alt+Shift+Tab) |
| Share | Switch Space Left (Ctrl+Left) |
| Options | Switch Space Right (Ctrl+Right) |
| PS | Toggle Dictation |
| Touchpad | Toggle Mission Control |
| R3 (right stick click) | Toggle Voice Control |
| D-Pad Up | Arrow Up / Zoom In Cmd+= *(Lightroom)* |
| D-Pad Down | Arrow Down / Zoom Out Cmd+- *(Lightroom)* |
| D-Pad Left | Arrow Left |
| D-Pad Right | Arrow Right |
| Left Stick Up | Shift+Up *(Emacs)* / Pane Up Cmd+Opt+Up *(Ghostty/iTerm2)* |
| Left Stick Down | Shift+Down *(Emacs)* / Pane Down Cmd+Opt+Down *(Ghostty/iTerm2)* |
| Left Stick Left | Shift+Left *(Emacs)* / Pane Left Cmd+Opt+Left *(Ghostty/iTerm2)* |
| Left Stick Right | Shift+Right *(Emacs)* / Pane Right Cmd+Opt+Right *(Ghostty/iTerm2)* |
| Right Stick Left | Prev Tab Ctrl+Shift+Tab *(Ghostty)* |
| Right Stick Right | Next Tab Ctrl+Tab *(Ghostty)* |

## R2 Modifier Mode (Hold R2)

Holding R2 activates an alternate layer for different actions:

| Input | Action |
|-------|--------|
| Square | Middle Click |
| Circle | Escape |
| X | Cmd+Return |
| L1 (hold) | Left Click Hold |
| L1 (release) | Left Click Release |
| R1 | Right Click |
| L2 | Toggle Dictation (press/release) |
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
- Sensitivity: 1.0px of stick deflection
- Throttled to 30Hz (every 2nd frame)
- Active when stick is outside the 20-point deadzone

### Stick Deadzone
- Center 128 ± 20 points (0-255 range)
- Prevents jittery small movements from registering

## App-Specific Bindings

### Ghostty / iTerm2
- **L1 / R1**: Window cycling (Cmd+Shift+` / Cmd+`)
- **D-Pad Left/Right**: Arrow keys (left/right)
- **Left Stick**: Pane navigation (Cmd+Opt+arrows)
- **Right Stick Left/Right**: Tab switching (Ctrl+Shift+Tab / Ctrl+Tab) *(Ghostty only)*

### Browsers (Firefox, Chrome, Safari)
- **L1 / R1**: Prev/Next Tab (Cmd+Shift+[ / Cmd+Shift+])
- **Triangle**: Close Tab (Cmd+W)
- **Square**: Space (scroll page)

### Claude / Codex
- **L1 / R1**: Prev/Next Tab (Cmd+Shift+[ / Cmd+Shift+])
- **Square**: Cmd+D hold *(Claude)* / Ctrl+M hold *(Codex)*

### Slack
- **Triangle**: Jump to unread (Cmd+Shift+A)
- **L1 / R1**: Navigate channels (Opt+Up / Opt+Down)

### Lightroom
- **X**: Before/After toggle (\\)
- **Triangle**: Zoom fit (Z)
- **Square**: X rating key
- **L1**: Space hold (loupe view)
- **D-Pad Up/Down**: Zoom In/Out (Cmd+= / Cmd+-)

### Emacs
- **Left Stick**: Arrow keys with Shift (for selection)

## Unused Inputs
- Right Stick Up/Down (no binding)
- Most buttons in R2 mode (only Square, Circle, X, L1, R1, L2, and both sticks are mapped)
