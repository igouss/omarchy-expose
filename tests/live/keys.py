"""Tap a sequence of evdev keys on one uinput keyboard. 'shift+KEY' holds shift; 'sleep:N' waits N seconds."""
import sys, time
from evdev import UInput, ecodes as e
steps: list[str] = sys.argv[1:]
codes: set[int] = {e.KEY_LEFTSHIFT}
for s in steps:
    if not s.startswith("sleep:"):
        codes.add(e.ecodes[s.split("+")[-1]])
ui: UInput = UInput({e.EV_KEY: sorted(codes)}, name="panorama-test")
time.sleep(0.8)
for s in steps:
    if s.startswith("sleep:"):
        time.sleep(float(s[6:])); continue
    shift: bool = s.startswith("shift+")
    k: int = e.ecodes[s.split("+")[-1]]
    if shift: ui.write(e.EV_KEY, e.KEY_LEFTSHIFT, 1); ui.syn()
    ui.write(e.EV_KEY, k, 1); ui.syn(); time.sleep(0.04)
    ui.write(e.EV_KEY, k, 0); ui.syn()
    if shift: ui.write(e.EV_KEY, e.KEY_LEFTSHIFT, 0); ui.syn()
    time.sleep(0.25)
ui.close()
