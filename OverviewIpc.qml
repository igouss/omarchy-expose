import QtQuick
import Quickshell.Io

// IpcHandler publishes its own properties, so the overview reference lives on this wrapper.
Item {
    property var overview: null

    IpcHandler {
        target: "expose"
        function open(): string {
            // Must not be overview.toggle(): that makes "open" a duplicate of
            // "toggle", so calling open on an already-open overview closes it.
            // Mirrors close(), which correctly calls dismiss().
            overview.open("{}");
            return "ok";
        }
        function close(): string {
            overview.dismiss();
            return "ok";
        }
        function toggle(): string {
            overview.toggle();
            return "ok";
        }
        function previewPlacement(mode: string): string {
            if (mode !== "in-place" && mode !== "centered")
                return "expected in-place or centered";
            overview.setPreviewPlacement(mode);
            return mode;
        }
        function windowFooterStyle(style: string): string {
            if (overview.windowFooterStyles.indexOf(style) === -1)
                return overview.expectedOneOf(overview.windowFooterStyles);
            overview.setWindowFooterStyle(style);
            return style;
        }
        function selectionStyle(style: string): string {
            if (overview.selectionStyles.indexOf(style) === -1)
                return overview.expectedOneOf(overview.selectionStyles);
            overview.setSelectionStyle(style);
            return style;
        }
        function animationStyle(style: string): string {
            if (overview.animationStyles.indexOf(style) === -1)
                return overview.expectedOneOf(overview.animationStyles);
            return overview.setAnimationStyle(style);
        }
        function animationDuration(style: string, value: real): string {
            if (overview.animationStyles.indexOf(style) === -1)
                return overview.expectedOneOf(overview.animationStyles);
            return String(overview.setAnimationDuration(style, value));
        }
        function animationDurationIn(style: string, value: real): string {
            if (overview.animationStyles.indexOf(style) === -1)
                return overview.expectedOneOf(overview.animationStyles);
            return String(overview.setAnimationDurationIn(style, value));
        }
        function animationDurationOut(style: string, value: real): string {
            if (overview.animationStyles.indexOf(style) === -1)
                return overview.expectedOneOf(overview.animationStyles);
            return String(overview.setAnimationDurationOut(style, value));
        }
        function slideDirection(direction: string): string {
            if (!overview.isSlideDirection(direction))
                return overview.expectedOneOf(overview.slideDirections);
            return overview.setSlideDirection(direction);
        }
        function slideDirectionIn(direction: string): string {
            if (!overview.isSlideDirection(direction))
                return overview.expectedOneOf(overview.slideDirections);
            return overview.setSlideDirectionIn(direction);
        }
        function slideDirectionOut(direction: string): string {
            if (!overview.isSlideDirection(direction))
                return overview.expectedOneOf(overview.slideDirections);
            return overview.setSlideDirectionOut(direction);
        }
        function backgroundBlur(value: real): string {
            return String(overview.setBackgroundBlur(value));
        }
        function backgroundDim(value: real): string {
            return String(overview.setBackgroundDim(value));
        }
        function settings(mode: string): string {
            if (mode === "open")
                overview.openSettings();
            else if (mode === "close")
                overview.closeSettings();
            else if (mode === "toggle")
                overview.settingsOpen ? overview.closeSettings() : overview.openSettings();
            else
                return "expected open, close, or toggle";
            return mode;
        }
        function hotCorner(mode: string): string {
            if (mode !== "on" && mode !== "off")
                return "expected on or off";
            overview.setHotCornerEnabled(mode === "on");
            return mode;
        }
        function hotCornerPosition(position: string): string {
            if (overview.hotCornerPositions.indexOf(position) === -1)
                return overview.expectedOneOf(overview.hotCornerPositions);
            overview.setHotCornerPosition(position);
            return position;
        }
        function hotCornerDelay(value: real): string {
            return String(overview.setHotCornerDelay(value));
        }
        function hotCornerAllDisplays(mode: string): string {
            if (mode !== "on" && mode !== "off")
                return "expected on or off";
            overview.setHotCornerAllDisplays(mode === "on");
            return mode;
        }
        function moveCursorToWindow(mode: string): string {
            if (mode !== "on" && mode !== "off")
                return "expected on or off";
            overview.setMoveCursorToWindow(mode === "on");
            return mode;
        }
        function multiMonitorMode(mode: string): string {
            if (mode !== "mirrored" && mode !== "per-monitor")
                return "expected mirrored or per-monitor";
            overview.setMultiMonitorMode(mode);
            return mode;
        }
    }
}
