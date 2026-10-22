# Troubleshooting


- **No thumbnails:** verify Hyprland exposes toplevel-export support and no screen-capture policy blocks Quickshell. Cards stay usable with fallback labels.
- **Workspace says “—”:** the native Hyprland model has not associated that Wayland toplevel yet. Very short-lived windows can briefly appear this way; restart Omarchy Shell if a normal window remains unassociated.
- **Plugin not listed:** run `omarchy plugin validate .`, then `omarchy-shell shell rescanPlugins`.
- **Shortcut does nothing:** run `hyprctl reload`, check `hyprctl configerrors`, and test `hyprctl dispatch 'hl.dsp.event("elendal.panorama:toggle")'` directly.
