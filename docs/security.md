# Security and system changes


Panorama runs unsandboxed inside Omarchy Shell with your user's permissions.

- Its helpers are plain Bash calling `hyprctl`, `jq`, `sleep`, and `timeout`.
- It reads window, workspace, and monitor state from Quickshell's native Hyprland model, activates or closes the windows you select, and temporarily raises Hyprland's blur while open, restoring the previous value on close.
- Settings writes touch only the plugin's entry in `~/.config/omarchy/shell.json`.
- No network, no privilege escalation, no package installs, no services.
