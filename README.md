# Plugin Manager

A standalone Omarchy plugin that manages installed Omarchy plugins from a popup panel: enable/disable, check for and apply updates, install new plugins from a git repo, and remove third-party plugins.

Built as a standard bar-widget popup (`KeyboardPanel`), so it works on a stock Omarchy shell with no other plugins required.

## Features

- **Enable / Disable**: Every discovered plugin (first-party Omarchy and third-party) with a toggle. Toggling routes through the shell's `PluginRegistry`, the same path `omarchy plugin enable/disable` uses.
- **Check for updates**: Scans every git-managed plugin folder, fetches each remote, and reports `Up to date` / `Update available` / `Error` per plugin, streamed live.
- **Update / Update all**: Apply a single update or update every plugin with a pending update in one go.
- **Install**: Add a plugin from a git repo URL (`omarchy plugin add`). Warns that plugins run as arbitrary, unsandboxed code before install.
- **Remove**: Lists only third-party plugins. Per-row trash button for a single remove, or a Select mode to check several and remove them in one go — always behind a confirmation dialog.
- **Source link**: Every git-managed plugin gets a `SOURCE` button that opens its remote repo URL.
- **Search & filter**: Filter by omarchy / third-party / Adna, or search by name, description, id, author, or kind.

## Installation

```bash
omarchy plugin add https://github.com/fross100/fross.plugins.manager --yes
omarchy plugin enable fross.plugins.manager
```

Or clone into your plugins directory:

```bash
git clone https://github.com/fross100/fross.plugins.manager ~/.config/omarchy/plugins/fross.plugins.manager
```

Then enable it in the plugin manager (or `omarchy plugin enable fross.plugins.manager`) and restart the shell.

## Usage

1. Click the plugin-manager button in the bar to open the popup.
2. Use the toggles to enable or disable plugins.
3. Use **Check updates** (sync icon) to see what is behind, then **Update** or **Update all**.
4. Use **Install** (download icon) to add a plugin from a git URL.
5. Use **Remove** (trash icon) to delete third-party plugins.
6. Press ESC or click outside the popup to close.

## Requirements

- Omarchy 4.x
- Quickshell
- `git`, `omarchy` CLI, and a terminal emulator (`wl-copy`/`yad` are not required)