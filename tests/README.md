Run `./validate` for the Qt 6 unit tests, QML lint, shell checks, and manifest
validation, including lint of the assembled runtime fixture.
The theme runtime check also exercises every settings page at desktop and narrow
widths, focus traversal and wrapping, disabled hot-corner controls, conditional
Motion controls, and scrolling focused controls into view. Run
`./tests/check-theme-runtime /tmp/panorama-settings` to save rendered page captures.
`./tests/check-blur-lock` checks the blur helper with a temporary runtime directory
and fake `hyprctl`: planted symlinks and invalid lock paths cannot damage files or
change compositor settings, and concurrent sessions serialize through restoration.
`./tests/check-settings-runtime` additionally runs Quickshell with a
temporary config and the installed Omarchy host's actual `PluginShellApi`,
`applyShellConfig`, `persistShellConfig`, and `updateEntryInline` implementations.
It creates no windows and does not access the live user's shell.json. Pass a shell
source directory as its argument to check another host version.

`./tests/check-hot-corner-runtime` extracts the actual inline `HotCornerTarget`
into an offscreen Qt Quick test. It checks immediate activation, one-shot dwell,
exit/disable cancellation, and transitions through the overlapping strips in both
directions. It runs as part of `./validate`.

`tst_screen_layout.qml` covers outermost-display selection with mixed logical
sizes, negative coordinates, stacked displays, layout changes, and removal.

`./tests/live/check-settings-focus` drives the running shell with a uinput
keyboard (sudo, python-evdev) after the working tree is installed into the plugin
directory and the shell restarted. It checks that Settings opened over IPC while
the overview is closed start with focus on the category list, and that the Motion
page's Animate preview leaves focus on its button. It restores every setting it
changes and never sends Escape.

`./tests/live/check-ipc` exercises the IPC commands (state, get, move, filter,
preview) against the running shell. It sends no keys and activates no window,
so it is safe while you type. IPC changes load only on a shell restart, not on
the plugin hot reload.

Pointer tests: read `omarchy-shell panorama state` before every click. A click on
the selection (the carousel's or strata's front card included) opens that window
and closes the overview; a middle click closes the window under the pointer, so
middle-click only a card whose `selection` is a throwaway test window. Prefer
`move`, `filter`, `preview`, and `activate` over clicks and keys.

For live multi-display checks, use a second physical or headless Hyprland output:

- Open on either display: both backdrops should blur/dim, with only one grid.
- Cross to the other display: search, Escape, and settings keyboard controls must
  still reach the grid. A backdrop click must dismiss without reaching an app.
- Toggle **Hot corner → All displays** and change corner positions; check that
  only the eligible displays activate Panorama, including after rearranging them.
- Add a display while open, then remove the grid's display: the grid should move
  to a remaining display and every other display should retain its backdrop.

The runtime check covers saved settings, 203 rapid edits, nested animation
settings, preservation of unknown fields and other entries, atomic file watching,
and external edits/deletions. Unit tests deterministically exercise delayed
snapshots, startup reads, no-op writes, rejection, and malformed configuration.

## Settings contract checked against source

- [Omarchy at 31bd80d](https://github.com/omacom/omarchy/blob/31bd80daa4613ffdee995ac27467fce5a2990806/shell/shell.qml):
  the asynchronous panel loader injects the scoped API after component creation;
  `updateEntryInline` replaces the complete matching entry; `false` also means
  unchanged; persistence updates host memory before the asynchronous disk write.
- [PluginShellApi](https://github.com/omacom/omarchy/blob/31bd80daa4613ffdee995ac27467fce5a2990806/shell/services/PluginShellApi.qml):
  no readable settings property. The host restricts `mutateShellConfig` to bar
  capabilities, so it cannot patch an overlay's settings.
- [Quickshell 0.3.1 FileView](https://github.com/quickshell-mirror/quickshell/blob/v0.3.1/src/io/fileview.cpp):
  reads and writes complete asynchronously, `reload()` can reuse an existing read,
  and `loaded` is emitted before that read job is cleared. Reloads and subsequent
  writes therefore run after the callback, via `Qt.callLater`.
- [Omadock at d2d355c](https://github.com/thepathless/omadock/blob/d2d355c58d229ab82d9e9bcf116a620a3c736617/Dock.qml):
  uses FileView for its own files. Panorama borrows the watched read pattern, but
  leaves shared shell.json writes with the host.

The store permits one unconfirmed replacement at a time, with newer edits kept
locally until disk acknowledgement. An unconfirmed write gets a fresh read after
two seconds; if it still differs, local edits are discarded and disk settings
are restored with a warning. This is not a disk-success acknowledgement from the
host, which the current API does not provide.

`./tests/render-look <LookType> <out.png> [selectedIndex]` renders one look
offscreen with six stand-in windows on three workspaces, without touching the
running shell, and fails on QML errors or binding loops. Thumbnails stay empty;
use it to iterate on a look's geometry and chrome before installing. Plugin hot
reload did not refresh the open overview in practice, so a live check needs a
shell restart; render offscreen first and restart once per finished change.

`./tests/mutate <lib.js> <tests/tst_x.qml> [function...]` runs an operator
mutation pass over a JS layout library against its test file (qmltestrunner has
no mutation tool). Classify every survivor: an equivalent mutant, a tuning
constant, or a missing test.
