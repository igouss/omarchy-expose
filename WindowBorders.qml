import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as Commons

// Window previews use compositor borders, independently of shell button states.
QtObject {
    id: root
    property var snapshot: ({ width: 0, active: "transparent", inactive: "transparent" })
    readonly property var activeSpec: spec(snapshot.active)
    readonly property var inactiveSpec: spec(snapshot.inactive)

    function spec(colors) {
        var gradient = Commons.Border.resolvedGradient(colors, "transparent", 1);
        var result = Commons.Border.flat(gradient.colors[0] || "transparent", root.snapshot.width);
        result.gradient = gradient;
        return result;
    }

    function gradientColors(raw) {
        // getoption emits packed ARGB hex, whereas Border expects CSS RGBA.
        return String(raw).trim().split(/\s+/).map(function (part) {
            if (/^-?\d+(?:\.\d+)?deg$/.test(part))
                return part;
            if (!/^[0-9a-f]{1,8}$/i.test(part))
                throw new Error("invalid Hyprland border color");
            var argb = ("00000000" + part).slice(-8);
            return "#" + argb.slice(2) + argb.slice(0, 2);
        }).join(" ");
    }

    function applySnapshot(raw) {
        try {
            // A JSON batch is a sequence of objects, not a JSON array.
            var options = JSON.parse("[" + raw.trim().replace(/}\s*{/g, "},{") + "]");
            var values = {};
            for (var i = 0; i < options.length; i++)
                values[options[i].option] = options[i];
            var width = values["general:border_size"].int;
            if (typeof width !== "number" || !isFinite(width) || width < 0)
                return;
            root.snapshot = {
                width: width,
                active: root.gradientColors(values["general:col.active_border"].gradient),
                inactive: root.gradientColors(values["general:col.inactive_border"].gradient)
            };
        } catch (error) {
            // A failed query must not replace the last known compositor state.
        }
    }

    function refresh() {
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE"))
            refreshTimer.restart();
    }

    property Timer refreshTimer: Timer {
        interval: 200
        onTriggered: {
            if (query.running)
                restart();
            else
                query.running = true;
        }
    }

    property Process query: Process {
        command: ["hyprctl", "-j", "--batch", "getoption general:border_size; getoption general:col.active_border; getoption general:col.inactive_border"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applySnapshot(text)
        }
    }

    Component.onCompleted: refresh()
}
