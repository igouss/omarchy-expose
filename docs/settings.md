# Settings


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
