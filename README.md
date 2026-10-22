# Panorama for Omarchy

Every open window at once, as live previews, in the look you like: a balanced **Grid**, a cover-flow **Carousel**, workspaces stacked as glass floors in **Strata**, frosted **Glass HUD** panes, a **CRT** terminal, a **Time Machine** of windows receding by when you last used them, a **Diorama**, a small isometric model of your desktop, an **Atlas** that maps every workspace side by side, or a **Helix** that winds them around a spiral. One key or a hot corner opens it; type to search, Space to Quick Look, Enter to open.

Panorama is a fork of [Exposé for Omarchy](https://github.com/kristofferR/omarchy-expose) by Kristoffer Risanger, which grew out of [Bird's Eye](https://github.com/harel/omarchy-birdseye) by Harel Malka. The grid, live previews, Quick Look, search, hot corner, and settings panel are theirs; Panorama adds the other looks and the parts listed below.

![The Grid look, inherited from Exposé](https://github.com/kristofferR/omarchy-expose/releases/download/v4.0.0/demo.gif)

## Where Panorama comes from

1. **Bird's Eye** by Harel Malka: the first Omarchy window overview plugin.
2. **Exposé** by Kristoffer Risanger (@kristofferR) rebuilt it into a macOS-style Exposé: live screencopy previews, Quick Look with the slow-motion Easter egg, type-to-search, workspace scope, multi-monitor support, a hot corner, and a full settings panel. Panorama starts from Exposé 5.0.0.
3. **Panorama** (@igouss) is a GitHub fork of Exposé with its history intact. It separates the window model from the drawing so the overview can have several looks, then adds them. Plugin id `elendal.panorama` and IPC target `panorama`, so it installs alongside Exposé without clashing (give each its own key and corner).

## Thank you

Thank you, Kristoffer, for Exposé: a careful, well-tested plugin that was a pleasure to build on. Thank you, Harel, for Bird's Eye, where it all started. If you enjoy Panorama, please consider sponsoring the original author:

[![Sponsor kristofferR on GitHub](https://img.shields.io/badge/Sponsor_kristofferR-%E2%99%A1-ec6cb9?style=for-the-badge)](https://github.com/sponsors/kristofferR)

## What's new in Panorama

- **Nine looks**, chosen on a new first Settings page or with `omarchy-shell panorama look <name>`:
  - **Grid**: Exposé's balanced rows, with an optional **Lift** selection style that raises and glows only the window Enter opens.
  - **Carousel**: the selection front and centre, the rest turned away on a reflective floor; it spins on a spring.
  - **Strata**: every workspace a glass floor in perspective, each window where it really is, including a scrolling layout's off-screen windows.
  - **Glass HUD**: frosted panes with large titles and one gradient ring that sweeps around the selection and slides between panes.
  - **CRT**: a terminal listing of every window beside a phosphor monitor of the selection, with a tmux-style status line.
  - **Time Machine**: windows recede down a starlit tunnel by when you last used them, the most recent in front, with a timeline ruler of every step back.
  - **Diorama**: the desktop as a small isometric model, every workspace a slab and every window a block on it with its live preview on top; the selection's block rises.
  - **Atlas**: the whole desktop as one map, workspaces side by side with every window at its real place; the camera flies to the selection, and the wheel zooms out to everything.
  - **Helix**: Strata's floors wound around a glowing spine like a spiral staircase; the tower turns to bring the selection's floor to the front.
- **Juice**: a Settings page of motion effects, each its own switch: springy motion, edge bump (an arrow with nowhere to go answers), activation punch (flash and sparks, or the CRT powering off), selection pulse, and pointer tilt.
- **Scriptable state**: `state`, `get`, `move`, `filter`, `preview`, and `activate` over IPC, so scripts and tests can read and drive the overview without a keyboard; `showFooter` restores the bottom text without editing `shell.json`.
- **One settings schema** drives values, validation, IPC, and the Settings pages, so a setting can no longer drift between them.

## What was fixed

Compared with Exposé 5.0.0:

- **Grid packing** never tried fewer rows than an estimate that ignored each card's title and padding; in a sweep of window sets it picked a smaller packing about half the time, losing up to half the card area. It now tries every row count.
- **Up and Down** could step sideways onto a shorter card in the same row; they now move between rows only.
- **Selection** was a position in a list rebuilt on every change, so closing a window while the overview was open could move the selection to a different window. It now holds the window itself.
- **The window you came from** lost its marker while the overview held keyboard focus; it is now remembered when the overview opens.
- **Right after a shell restart** Hyprland's active window is not known yet, so the first open selected the first listed window; it now falls back to the head of Hyprland's focus history.
- **Opening a window** waited a fixed delay through a helper process; it is now dispatched from the shell as soon as the overlay is gone.
- **Footer styles**: every style drew the Rail style's framed card background; now only Rail does.
- **Tests and lint**: under Qt 6.12, Omarchy's `Color` singleton resolved to Qt's own `Color` type, which turned the theme, settings, and lint checks red for an unrelated reason and hid a real bug. They now resolve correctly, lint covers every QML file, and the runtime test loads every look.

## Highlights

- **Live previews.** Cards are real screencopy views, so videos keep playing and terminals keep scrolling. The Omarchy desktop behind the grid stays live too.
- **Looks.** Grid packs every preview into balanced rows; Carousel puts the selected window front and centre with the rest turned away in perspective on a reflective floor, spinning on a spring as you move (Left/Right, the scroll wheel, or a click on a side card). Strata lays every workspace back as a glass floor, stacked in perspective, with each window where it really is (a scrolling layout's off-screen windows sit beside the monitor's outline); Up/Down climb between floors. Glass HUD sets frosted glass panes on the grid's rows, each title in large type, with one gradient ring sweeping around the selection that slides from pane to pane. CRT lists every window like a terminal, beside a phosphor monitor of the selection under scanlines; the prompt echoes your filter, the list scrolls to keep the selection in view, and Space fills the screen with the monitor. Time Machine orders windows by Hyprland's focus history: the window you came from is in front, Up (or the wheel) steps back in time with each older window waiting behind it, and newer windows fly past the camera as you go; the ruler on the right marks every step and takes clicks. Diorama builds a model of every workspace as a slab in a grid, each window a block at its real place (a scrolling layout's off-screen windows included); arrows move by where the blocks sit on screen, the selection's block rises on a spring and hops at an edge, and Quick Look unfolds its lid to fill the screen. Atlas lays every workspace side by side on one map at the same scale, with a graticule, a scale bar, and a minimap of where the camera is looking; each open starts over everything and flies in to the selection, arrows move across workspaces by map position, and scrolling down zooms out to the whole map (up zooms back in). Helix winds Strata's floors around a spine, each a step further round and lower; Up/Down (or the wheel) turn the tower floor by floor, with windows at their real places on each.
- **Quick Look.** Space enlarges any preview and restores it again. Shift+Space does it in slow motion, like the classic macOS Easter egg.
- **Search.** Just start typing to filter windows by title or application.
- **Workspace scope.** Press Tab to switch between every window and windows on the current workspace, and pick which of the two the overview opens with. Per-monitor mode evaluates the current workspace of the selected display.
- **Multi-monitor layouts.** Every display blurs and dims, with one grid on the focused display (or the display whose hot corner was used). All displays shows every window there; This display keeps that display's own windows.
- **Built for Omarchy.** Runs inside Omarchy Shell, follows the active theme, and adds no packages, services, or daemons.
- **Hot corner.** Toggle the overview by flinging the pointer into a corner. Uses the outermost display by default, with an option for all displays.

Everything is tunable from the built-in Settings panel and over IPC, and changes apply instantly.

## Requirements

- Omarchy Quattro with the native shell plugin system
- `jq`

The underlying Quickshell, Hyprland, Bash, and coreutils support ships with Omarchy, so no separate compositor setup is needed.

## Install

```sh
omarchy plugin add https://github.com/igouss/omarchy-panorama.git --enable
```

That's it: the top-left hot corner works right away. Optionally, bind a key in `~/.config/hypr/bindings.lua`, then run `hyprctl reload`:

```lua
o.bind("SUPER + A", "Panorama", hl.dsp.event("elendal.panorama:toggle"))
```

Any unused chord works. Avoid modifier-only bindings such as standalone Super; Hyprland cannot reliably distinguish them from the start of normal Super shortcuts.

To keep workspace swipes from changing the desktop behind Panorama, replace your workspace gesture in `~/.config/hypr/input.lua` with:

```lua
local panorama_gesture_path = os.getenv("HOME") .. "/.config/omarchy/plugins/elendal.panorama/workspace-gesture.lua"
local panorama_gesture_loader = loadfile(panorama_gesture_path)
if panorama_gesture_loader then
  panorama_gesture_loader()({ fingers = 4, scale = 0.5 })
else
  hl.gesture({ fingers = 4, direction = "horizontal", scale = 0.5, action = "workspace" })
end
```

Adjust `fingers` and `scale` to match your preferred gesture. Only the workspace gesture is swallowed while Panorama is open; media keys and other compositor shortcuts keep working.

### Update

```sh
omarchy plugin update elendal.panorama --yes
```

### Remove

Delete the Panorama binding from `~/.config/hypr/bindings.lua`, then:

```sh
omarchy plugin remove elendal.panorama --yes
hyprctl reload
```

Removal leaves nothing behind: Panorama keeps no files outside its plugin directory and its entry in `~/.config/omarchy/shell.json`.

## Controls

| Key | Action |
| --- | --- |
| Arrow keys | Move selection |
| Any character | Search by title or application |
| Space | Quick Look the hovered or selected preview (enlarge or restore) |
| Shift+Space | Quick Look in slow motion |
| Tab | Toggle all windows or the current workspace |
| Shift+Q | Close the selected window |
| Enter | Activate the selected window |
| Escape | Restore an enlarged preview; press again to close |

Clicking a card activates it; middle-clicking closes it. Activation moves the pointer to the chosen window by default; this is a setting, not a change to Hyprland's global cursor behavior.

The window grid stays on the display where Panorama opened. Every display gets the same background blur and dim; clicking any backdrop dismisses Panorama without clicking through to the desktop. With **All displays**, the grid shows every window. With **This display**, it shows only windows that already belong to that display; when showing the current workspace, it uses the one active on that display.

Hot corners default to the outermost display: left corners use the leftmost display, and right corners use the rightmost. If displays share that edge, the topmost or bottommost one wins according to the chosen corner. Enable **Hot corner → Use on all displays** to use the chosen corner on every display.

## Settings

Open **Settings** from the footer while the overview is open. It is fully keyboard driven: 1-8 jump to a section, Up/Down move between controls, Left/Right adjust sliders and choices, Space or Enter flip toggles and press buttons, Escape closes. Changes apply immediately. Settings are grouped into **Look**, **Appearance**, **Windows**, **Window labels**, **Workspaces**, **Hot corner**, **Motion**, and **Juice**, with explanatory text beneath each control:

- Look: Grid (default), Carousel, Strata, Glass HUD, Time Machine, Diorama, Atlas, Helix, or CRT (its phosphor is your theme's accent colour). Window labels and selection highlight shape the grid only; their settings say so while another look is active
- Juice, each effect its own switch (all on by default): springy motion (moves overshoot and settle; carousel cards stretch as they travel, the grid's lifted card pops) and edge bump (an arrow with no window that way shakes the selection; the carousel rubber-bands), and activation punch (the opened window flashes, jumps toward you and throws sparks; the overview closes about 0.2 s later, instantly with punch off; the CRT's monitor powers off to a line and a dot instead), and selection pulse (the selection's glow breathes; carousel and the grid's Lift highlight; the CRT's cursor), and pointer tilt (the card under the pointer leans toward it in 3D; in the carousel only the front card; not in the CRT, whose screen is flat, or the Diorama, whose blocks stand on the model)
- Opening animation: Original (default), Fade, Zoom, or Slide
- Animation duration saved per mode, linked for in/out by default or expandable to separate timings
- Slide direction: left (default), right, up, or down. Splitting in/out splits both speed and direction
- Background blur (0–20) and dim (0–90)
- Selection highlight: outline (default) or lift, which raises and lights only the selected window and marks the current one with a dot
- Quick Look position: in-place or centered
- Opens with: all workspaces (default) or the current workspace; Tab still switches either way
- Workspace names: full (default) or slot only, which prints just the trailing slot of names like `<monitor description>:3` that per-monitor workspace plugins produce
- Window footer style: floating, integrated, overlay, or centered
- Windows to include: All displays (windows from every display) or This display (only that display's windows)
- Bottom text visibility. Hiding it requires confirmation and removes the Settings link
- Hot corner on/off, position (disable the same corner in other hot-corner plugins to avoid overlap), All displays (off by default), and activation delay (0–1000 ms of pointer dwell before it fires; 0 is instant)
- Move cursor to the activated window on/off

Every reversible setting is also scriptable:

```sh
omarchy-shell panorama toggle                      # also: open, close
omarchy-shell panorama settings toggle             # also: open, close
omarchy-shell panorama animationStyle original     # original | fade | zoom | slide
omarchy-shell panorama animationDuration original 190    # linked in/out, 100-800 ms
omarchy-shell panorama animationDurationIn original 190  # separate opening speed
omarchy-shell panorama animationDurationOut original 190 # separate closing speed
omarchy-shell panorama slideDirection left         # left | right | up | down, both halves
omarchy-shell panorama slideDirectionIn left       # separate opening side, also splits slide timing
omarchy-shell panorama slideDirectionOut right     # separate closing side, also splits slide timing
omarchy-shell panorama backgroundBlur 4            # 0-20
omarchy-shell panorama backgroundDim 6             # 0-90
omarchy-shell panorama previewPlacement in-place   # in-place | centered
omarchy-shell panorama windowFooterStyle floating  # floating | integrated | overlay | centered
omarchy-shell panorama selectionStyle outline      # outline | lift
omarchy-shell panorama look strata                 # grid, carousel, strata, hud, crt, time, diorama, atlas, or helix
omarchy-shell panorama juice spring off            # spring, edgeBump, punch, pulse, or tilt; on or off
omarchy-shell panorama multiMonitorMode mirrored   # mirrored | per-monitor
omarchy-shell panorama hotCorner on                # on | off
omarchy-shell panorama hotCornerPosition top-left  # top-left | top-right | bottom-left | bottom-right
omarchy-shell panorama hotCornerAllDisplays off    # off: outermost display (default) | on: every display
omarchy-shell panorama hotCornerDelay 0            # 0-1000 ms of dwell before it fires
omarchy-shell panorama moveCursorToWindow on       # on | off
omarchy-shell panorama showFooter on               # on | off; brings back the bottom text and its Settings link
omarchy-shell panorama get look                    # any setting above, or a juice effect: spring, pulse, ...
```

The open overview can be driven and inspected too, without a keyboard:

```sh
omarchy-shell panorama state                       # JSON: opened, look, windows, filter, selection, preview, ...
omarchy-shell panorama move right                  # left | right | up | down; prints the new selection
omarchy-shell panorama filter term                 # prints how many windows match; "" clears it
omarchy-shell panorama preview                     # toggles Quick Look on the selection
omarchy-shell panorama activate                    # opens the selection, as Enter does
```

Each of these answers `closed` while the overview is closed.

## Security and system changes

Panorama runs unsandboxed inside Omarchy Shell with your user's permissions.

- Its helpers are plain Bash calling `hyprctl`, `jq`, `sleep`, and `timeout`.
- It reads window, workspace, and monitor state from Quickshell's native Hyprland model, activates or closes the windows you select, and temporarily raises Hyprland's blur while open, restoring the previous value on close.
- Settings writes touch only the plugin's entry in `~/.config/omarchy/shell.json`.
- No network, no privilege escalation, no package installs, no services.

## Troubleshooting

- **No thumbnails:** verify Hyprland exposes toplevel-export support and no screen-capture policy blocks Quickshell. Cards stay usable with fallback labels.
- **Workspace says “—”:** the native Hyprland model has not associated that Wayland toplevel yet. Very short-lived windows can briefly appear this way; restart Omarchy Shell if a normal window remains unassociated.
- **Plugin not listed:** run `omarchy plugin validate .`, then `omarchy-shell shell rescanPlugins`.
- **Shortcut does nothing:** run `hyprctl reload`, check `hyprctl configerrors`, and test `hyprctl dispatch 'hl.dsp.event("elendal.panorama:toggle")'` directly.

## Credits

Panorama is a fork of [Exposé for Omarchy](https://github.com/kristofferR/omarchy-expose) by Kristoffer Risanger, itself based on [Bird's Eye](https://github.com/harel/omarchy-birdseye) by Harel Malka. Both are MIT licensed, as is Panorama.

## License

MIT
