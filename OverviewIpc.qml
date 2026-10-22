import QtQuick
import Quickshell.Io
import "SettingsSchema.js" as SettingsSchema

// IpcHandler publishes its own properties, so the overview reference lives on this wrapper.
// Each command is declared so it can be discovered; simple settings validate
// through the schema, so their rejection text names the real options.
Item {
    property var overview: null

    function animationStyleError(style) {
        return SettingsSchema.parseIpc("animationStyle", style).error;
    }

    function slideDirectionError(direction) {
        return overview.isSlideDirection(direction) ? "" : SettingsSchema.expectedOneOf(overview.slideDirections);
    }

    IpcHandler {
        target: "expose"
        function open(): string {
            // Must not be overview.toggle(): that makes "open" a duplicate of
            // "toggle", so calling open on an already-open overview closes it.
            // Mirrors close(), which correctly calls dismiss().
            overview.open();
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
        function look(name: string): string { return overview.setSettingFromIpc("look", name); }
        function previewPlacement(mode: string): string { return overview.setSettingFromIpc("previewPlacement", mode); }
        function windowFooterStyle(style: string): string { return overview.setSettingFromIpc("windowFooterStyle", style); }
        function selectionStyle(style: string): string { return overview.setSettingFromIpc("selectionStyle", style); }
        function animationStyle(style: string): string { return overview.setSettingFromIpc("animationStyle", style); }
        function backgroundBlur(value: real): string { return overview.setSettingFromIpc("backgroundBlur", value); }
        function backgroundDim(value: real): string { return overview.setSettingFromIpc("backgroundDim", value); }
        function hotCorner(mode: string): string { return overview.setSettingFromIpc("hotCornerEnabled", mode); }
        function hotCornerPosition(position: string): string { return overview.setSettingFromIpc("hotCornerPosition", position); }
        function hotCornerDelay(value: real): string { return overview.setSettingFromIpc("hotCornerDelay", value); }
        function hotCornerAllDisplays(mode: string): string { return overview.setSettingFromIpc("hotCornerAllDisplays", mode); }
        function moveCursorToWindow(mode: string): string { return overview.setSettingFromIpc("moveCursorToWindow", mode); }
        function multiMonitorMode(mode: string): string { return overview.setSettingFromIpc("multiMonitorMode", mode); }
        function initialWorkspaceScope(scope: string): string { return overview.setSettingFromIpc("initialWorkspaceScope", scope); }
        function workspaceLabelStyle(style: string): string { return overview.setSettingFromIpc("workspaceLabelStyle", style); }
        function animationDuration(style: string, value: real): string {
            return animationStyleError(style) || String(overview.setAnimationDuration(style, value));
        }
        function animationDurationIn(style: string, value: real): string {
            return animationStyleError(style) || String(overview.setAnimationDurationIn(style, value));
        }
        function animationDurationOut(style: string, value: real): string {
            return animationStyleError(style) || String(overview.setAnimationDurationOut(style, value));
        }
        function slideDirection(direction: string): string {
            return slideDirectionError(direction) || overview.setSlideDirection(direction);
        }
        function slideDirectionIn(direction: string): string {
            return slideDirectionError(direction) || overview.setSlideDirectionIn(direction);
        }
        function slideDirectionOut(direction: string): string {
            return slideDirectionError(direction) || overview.setSlideDirectionOut(direction);
        }
    }
}
