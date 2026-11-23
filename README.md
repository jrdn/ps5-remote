# ps5-remote

A macOS menu-bar app that maps DualSense controller buttons, triggers, and sticks to keyboard shortcuts, mouse actions, Mission Control, and Voice Control. Bindings are configurable per foreground app and can be organized into layers activated by holding a controller button.

The app is implemented in Swift with AppKit, IOKit, CoreGraphics, and YAML configuration. It requires macOS and the native Apple development toolchain; this repository does not currently define a CI workflow for native build verification.

## Install and run

Use [mise](https://mise.jdx.dev/) to build and install the app:

- `mise run build` compiles the command-line app.
- `mise run bundle` builds a signed `PS5 Remote.app` bundle (creates a local self-signed signing identity if needed).
- `mise run install` installs the app under `~/Applications` and launches it. Pass `--system` to use `/Applications` instead.
- `mise run run` runs the utility from the repository using `bindings.yaml`.
- `mise run dev` watches Swift sources and rebuilds/runs on changes.
- `mise run clean` removes build artifacts; `mise run rebuild` cleans and builds.

On first launch, macOS may request Input Monitoring, Accessibility, and Automation permissions. The menu-bar status icon warns when a permission is missing and links to the relevant settings. The menu can open the active config and log, reload bindings, and toggle Launch at Login. See `~/Library/Logs/PS5 Remote.log` for application output.

## Configuration

The installed app seeds its default configuration at `~/.config/ps5-remote/bindings.yaml` from the bundled `bindings.yaml` on first launch. Edit the user config from the menu bar's **Open Config** command, then choose **Reload Config**. When running from the repository, pass `--config <path>` to select a configuration file; `mise run run` uses the repository's `bindings.yaml`.

Bindings support app-specific rules, key combinations, held keys, mouse clicks, release actions, built-in Mission Control and Voice Control actions, plus layers that change stick behavior or mappings while a button is held. The checked-in [`bindings.yaml`](bindings.yaml) documents the schema and provides the default mappings. See [`BINDINGS.md`](BINDINGS.md) for the current mapping reference.

## Development

The app reads HID events from a connected DualSense controller and uses macOS APIs to synthesize input. Build and exercise it on macOS with the documented mise tasks; Linux environments do not have the required Swift/macOS frameworks. Review [`BINDINGS.md`](BINDINGS.md) alongside `bindings.yaml` when changing default mappings.
