import QtQuick
import "WindowModel.js" as WindowModel
import "SettingsSchema.js" as SettingsSchema
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons as Commons
import "ScreenLayout.js" as ScreenLayout

// Settings read from shell.json and the overview's session state.
Item {
    id: root

    property var shell: null
    property var manifest: null
    readonly property alias windowBorders: windowBorders
    WindowBorders { id: windowBorders }
    readonly property string pluginId: String((root.manifest && root.manifest.id) || "elendal.panorama")
    readonly property string pluginDir: String((root.manifest && root.manifest.__sourceDir)
        || (Quickshell.env("HOME") + "/.config/omarchy/plugins/" + root.pluginId))
    readonly property var pluginEntry: pluginSettings.entry

    PluginSettings {
        id: pluginSettings
        pluginId: root.pluginId
        shell: root.shell
        onReloadRequested: Qt.callLater(pluginSettingsFile.reload)
    }

    FileView {
        id: pluginSettingsFile
        // Match the host's userConfigPath, which does not use XDG_CONFIG_HOME.
        path: Quickshell.env("HOME") + "/.config/omarchy/shell.json"
        watchChanges: true
        printErrors: false
        onLoaded: pluginSettings.load(text())
        onLoadFailed: function(error) {
            pluginSettings.loadFailed();
            console.warn(root.pluginId + ": could not load shell.json: " + error);
        }
        onFileChanged: Qt.callLater(pluginSettingsFile.reload)
    }
    readonly property string look: SettingsSchema.read(root.pluginEntry, "look")
    readonly property string previewPlacement: SettingsSchema.read(root.pluginEntry, "previewPlacement")
    readonly property string windowFooterStyle: SettingsSchema.read(root.pluginEntry, "windowFooterStyle")
    property var originToplevel: null
    readonly property string selectionStyle: SettingsSchema.read(root.pluginEntry, "selectionStyle")
    readonly property bool juiceSpring: SettingsSchema.read(root.pluginEntry, "juiceSpring")
    readonly property bool juiceEdgeBump: SettingsSchema.read(root.pluginEntry, "juiceEdgeBump")
    readonly property bool juicePunch: SettingsSchema.read(root.pluginEntry, "juicePunch")
    readonly property bool juicePulse: SettingsSchema.read(root.pluginEntry, "juicePulse")
    readonly property bool juiceTilt: SettingsSchema.read(root.pluginEntry, "juiceTilt")
    readonly property var animationStyles: SettingsSchema.values("animationStyle")
    readonly property string animationStyle: SettingsSchema.read(root.pluginEntry, "animationStyle")
    readonly property var defaultAnimationDurations: ({ original: 190, fade: 400, zoom: 320, slide: 320 })
    readonly property var animationTimings: {
        var configuredTimings = root.pluginEntry && root.pluginEntry.animationTimings
            && typeof root.pluginEntry.animationTimings === "object"
            ? root.pluginEntry.animationTimings
            : null;
        var configuredDurations = root.pluginEntry && root.pluginEntry.animationDurations
            && typeof root.pluginEntry.animationDurations === "object"
            ? root.pluginEntry.animationDurations
            : null;
        var configured = configuredTimings || configuredDurations || {};
        var legacyRaw = root.pluginEntry ? root.pluginEntry.animationDuration : undefined;
        var legacy = legacyRaw === null || legacyRaw === undefined ? NaN : Number(legacyRaw);
        function timingFor(style) {
            var raw = configured[style];
            var isObject = raw !== null && raw !== undefined && typeof raw === "object";
            var scalar = raw === null || raw === undefined ? NaN : Number(raw);
            var separate = isObject && raw.separate === true;
            var inValue = isObject ? Number(raw["in"]) : scalar;
            var outValue = isObject ? Number(raw["out"]) : scalar;
            if (!isFinite(inValue) && isFinite(legacy))
                inValue = legacy;
            if (!isFinite(outValue) && isFinite(legacy))
                outValue = legacy;
            if (!isFinite(inValue))
                inValue = root.defaultAnimationDurations[style];
            if (!isFinite(outValue))
                outValue = inValue;
            return {
                "in": root.clampAnimationDuration(inValue),
                "out": root.clampAnimationDuration(outValue),
                separate: separate
            };
        }
        return {
            original: timingFor("original"),
            fade: timingFor("fade"),
            zoom: timingFor("zoom"),
            slide: timingFor("slide")
        };
    }
    readonly property var slideVectors: ({
        left: {x: -1, y: 0},
        right: {x: 1, y: 0},
        up: {x: 0, y: -1},
        down: {x: 0, y: 1}
    })
    readonly property var slideDirections: Object.keys(root.slideVectors)
    // {"in", "out"}. A bare string in config is shorthand for both. The slide
    // timing's `separate` flag decides whether "out" is honored or mirrors "in".
    readonly property var slideDirection: {
        var raw = root.pluginEntry ? root.pluginEntry.slideDirection : undefined;
        var isObject = raw !== null && raw !== undefined && typeof raw === "object";
        var inValue = root.normalizeSlideDirection(isObject ? raw["in"] : raw);
        var outValue = root.animationTimingFor("slide").separate
            ? root.normalizeSlideDirection(isObject ? raw["out"] : raw)
            : inValue;
        return {"in": inValue, "out": outValue};
    }
    // Latched by animateMotionTo when a transition starts from rest, so reversing
    // mid-flight slides back out the side it came from instead of popping across.
    property string slideMotionDirection: ""
    readonly property var slideVector: root.slideVectors[root.slideMotionDirection] || root.slideVectors[root.slideDirection["in"]]
    readonly property real slideOffsetFraction: root.animationStyle === "slide"
        ? 0.11 * (1 - root.motionProgress)
        : 0
    readonly property real windowFooterHeight: root.windowFooterStyle === "overlay" ? 0 : Commons.Style.space(40)
    readonly property int backgroundBlur: SettingsSchema.read(root.pluginEntry, "backgroundBlur")
    readonly property int backgroundDim: SettingsSchema.read(root.pluginEntry, "backgroundDim")
    // Off until settings load, so a saved "off" never flashes the corner on.
    readonly property bool hotCornerEnabled: pluginSettings.ready && SettingsSchema.read(root.pluginEntry, "hotCornerEnabled")
    readonly property string hotCornerPosition: SettingsSchema.read(root.pluginEntry, "hotCornerPosition")
    readonly property bool hotCornerOnTop: root.hotCornerPosition.indexOf("top-") === 0
    readonly property bool hotCornerOnLeft: root.hotCornerPosition.indexOf("-left") !== -1
    readonly property bool hotCornerAllDisplays: SettingsSchema.read(root.pluginEntry, "hotCornerAllDisplays")
    readonly property var hotCornerScreens: root.hotCornerEnabled
        ? ScreenLayout.hotCornerScreens(Quickshell.screens,
            Hyprland.monitors ? Hyprland.monitors.values : [],
            root.hotCornerPosition, root.hotCornerAllDisplays)
        : []

    // How long the pointer has to rest in the corner before it fires. Zero
    // keeps the original instant trip; longer dwells stop stray flings.
    readonly property int hotCornerDelay: SettingsSchema.read(root.pluginEntry, "hotCornerDelay")
    // Which windows the overview starts with. "all" keeps every workspace, as
    // before; "current" opens on the active workspace and leaves Tab to widen.
    readonly property string initialWorkspaceScope: SettingsSchema.read(root.pluginEntry, "initialWorkspaceScope")
    // How a workspace is named on the cards and in the scope indicator. Plugins
    // such as per-monitor-workspaces name a workspace "<monitor description>:<slot>",
    // which is far wider than a card footer; "slot" prints the trailing slot only.
    readonly property string workspaceLabelStyle: SettingsSchema.read(root.pluginEntry, "workspaceLabelStyle")
    // Reach farther along both screen edges than into the desktop. Fast flings
    // are easier to catch without stealing a large square from the bar below.
    readonly property int hotCornerReach: Commons.Style.space(48)
    readonly property int hotCornerDepth: Commons.Style.space(6)
    readonly property bool moveCursorToWindow: SettingsSchema.read(root.pluginEntry, "moveCursorToWindow")
    readonly property string multiMonitorMode: SettingsSchema.read(root.pluginEntry, "multiMonitorMode")
    readonly property bool showFooter: SettingsSchema.read(root.pluginEntry, "showFooter")
    property bool opened: false
    property bool surfaceMounted: false
    property bool hotCornerArmed: true
    property string filterText: ""
    property string workspaceScope: "all"
    // Selection state holds windows, not positions in filteredToplevels, so it
    // survives the list being rebuilt by filtering, scope, or windows closing.
    property var selectedToplevel: null
    property var hoveredToplevel: null
    property var previewToplevel: null
    property var previewExitToplevel: null
    // Window to focus once the overlay releases the keyboard.
    property var pendingActivation: null
    property bool previewSlowMotion: false
    property bool previewNavigationSlowMotion: false
    property bool openingPending: false
    property bool settingsOpen: false
    property int settingsCategoryIndex: 0
    property bool footerHideConfirmationOpen: false
    property bool footerHideAcknowledged: false
    property string animationDurationPreviewStyle: ""
    property real animationInDurationPreview: -1
    property real animationOutDurationPreview: -1
    property real backgroundBlurPreview: -1
    property real backgroundDimPreview: -1
    property real hotCornerDelayPreview: -1
    readonly property real effectiveBackgroundBlur: root.backgroundBlurPreview >= 0 ? root.backgroundBlurPreview : root.backgroundBlur
    readonly property real effectiveBackgroundDim: root.backgroundDimPreview >= 0 ? root.backgroundDimPreview : root.backgroundDim
    readonly property int effectiveHotCornerDelay: root.hotCornerDelayPreview >= 0 ? Math.round(root.hotCornerDelayPreview) : root.hotCornerDelay
    readonly property int previewAnimationDuration: root.previewSlowMotion || root.previewNavigationSlowMotion ? 4000 : 190
    readonly property int previewFadeDuration: root.previewSlowMotion || root.previewNavigationSlowMotion ? 4000 : 130
    readonly property int previewAnimationEasing: root.previewNavigationSlowMotion ? Easing.InOutCubic : Easing.OutQuart
    property bool backgroundBlurPrimed: false
    property bool backgroundBlurFailed: false
    property bool dismissNotifyShell: false
    // 0 idle, 1 restoring the desktop blur while the surface is transparent.
    property int backgroundBlurReleasePhase: 0
    property real motionProgress: 0
    property real motionTarget: 0
    // Cards bind to this instead of motionProgress so the animation only
    // notifies them twice, not once per frame.
    readonly property bool motionSettled: root.motionProgress >= 0.999
    property int lastRequestedBlur: -1
    property var iconCache: ({})
    property int modelRevision: 0
    property var sessionToplevels: []
    property var sessionAspectRatios: []
    readonly property var allToplevels: Hyprland.toplevels ? Hyprland.toplevels.values : []
    readonly property string focusedMonitorName: Hyprland.focusedMonitor
        ? String(Hyprland.focusedMonitor.name || "")
        : ""
    property string overviewScreenName: ""
    property bool overviewScreenPinned: false
    readonly property var effectiveOverviewScreen: {
        var screens = Quickshell.screens;
        var wanted = String(root.overviewScreenName || "");
        var fallback = null;
        for (let index = 0; index < screens.length; index++) {
            let screen = screens[index];
            if (!screen)
                continue;
            if (!fallback)
                fallback = screen;
            if (wanted && String(screen.name || "") === wanted)
                return screen;
        }
        return fallback;
    }
    readonly property string effectiveOverviewScreenName: root.effectiveOverviewScreen
        ? String(root.effectiveOverviewScreen.name || "")
        : ""
    readonly property string keyboardScreenName: {
        if (root.effectiveOverviewScreenName && (root.surfaceMounted || root.overviewScreenName))
            return root.effectiveOverviewScreenName;
        if (root.overviewScreenName)
            return root.overviewScreenName;
        if (root.focusedMonitorName)
            return root.focusedMonitorName;
        var active = Hyprland.activeToplevel;
        if (active && active.monitor)
            return String(active.monitor.name || "");
        return Quickshell.screens.length ? String(Quickshell.screens[0].name || "") : "";
    }
    // Only the selected display creates cards and screencopy captures.
    readonly property var mountedScreens: {
        if (!root.surfaceMounted || !root.effectiveOverviewScreen)
            return [];
        return [root.effectiveOverviewScreen];
    }
    readonly property var backdropScreens: {
        if (!root.surfaceMounted)
            return [];
        return Quickshell.screens.filter(function (screen) {
            return screen !== root.effectiveOverviewScreen;
        });
    }

    readonly property var filteredToplevels: {
        var revision = root.modelRevision;
        return root.toplevelsForScreen(root.keyboardScreenName);
    }
    readonly property var selection: WindowModel.selectionFor(root.filteredToplevels, root.selectedToplevel, root.originToplevel)

    readonly property alias previewExitTimer: previewExitTimerObject

    function monitorForScreen(screenName) {
        var wanted = String(screenName || "");
        var monitors = Hyprland.monitors ? Hyprland.monitors.values : [];
        for (let index = 0; index < monitors.length; index++) {
            let monitor = monitors[index];
            if (monitor && monitor.name === wanted)
                return monitor;
        }
        return null;
    }

    function workspaceForScreen(screenName) {
        if (root.multiMonitorMode === "per-monitor") {
            let monitor = root.monitorForScreen(screenName);
            if (monitor && monitor.activeWorkspace)
                return monitor.activeWorkspace;
        }
        return Hyprland.focusedWorkspace || null;
    }

    function isOnScreen(top, screenName) {
        return WindowModel.isOnScreen(top, screenName, root.multiMonitorMode === "per-monitor");
    }

    function toplevelsOnScreen(screenName) {
        var result = [];
        var source = root.surfaceMounted || root.openingPending ? root.sessionToplevels : root.allToplevels;
        for (let index = 0; index < source.length; index++) {
            let top = source[index];
            if (top && root.isOnScreen(top, screenName))
                result.push(top);
        }
        return result;
    }

    function toplevelsForScreen(screenName) {
        var needle = root.filterText.toLowerCase();
        var currentWorkspace = root.workspaceForScreen(screenName);
        var candidates = root.toplevelsOnScreen(screenName);
        var result = [];
        for (let index = 0; index < candidates.length; index++) {
            let top = candidates[index];
            if (root.workspaceScope === "current" && !WindowModel.isOnWorkspace(top, currentWorkspace))
                continue;
            let haystack = WindowModel.searchTextFor(top);
            if (!needle || haystack.indexOf(needle) !== -1)
                result.push(top);
        }
        return result;
    }

    function updatePluginSetting(name, value) {
        return pluginSettings.update(name, value);
    }

    function clampAnimationDuration(value) {
        var numeric = Number(value);
        if (!isFinite(numeric))
            return 320;
        var clamped = Math.max(100, Math.min(800, numeric));
        return Math.round(clamped / 10) * 10;
    }

    function animationTimingFor(style) {
        var mode = root.animationStyles.indexOf(style) !== -1 ? style : "original";
        return root.animationTimings[mode];
    }

    function animationInDurationFor(style) {
        if (root.animationInDurationPreview >= 0 && root.animationDurationPreviewStyle === style)
            return root.animationInDurationPreview;
        return Number(root.animationTimingFor(style)["in"]);
    }

    function animationOutDurationFor(style) {
        if (root.animationOutDurationPreview >= 0 && root.animationDurationPreviewStyle === style)
            return root.animationOutDurationPreview;
        return Number(root.animationTimingFor(style)["out"]);
    }

    function isSlideDirection(value) {
        var direction = String(value === null || value === undefined ? "" : value);
        return root.slideDirections.indexOf(direction) !== -1;
    }

    function normalizeSlideDirection(value) {
        var direction = String(value === null || value === undefined ? "" : value);
        return root.isSlideDirection(direction) ? direction : "left";
    }

    function clearPreview() {
        previewExitTimer.stop();
        root.previewSlowMotion = false;
        root.previewNavigationSlowMotion = false;
        root.previewToplevel = null;
        root.previewExitToplevel = null;
    }

    function clearOverviewScreen() {
        root.overviewScreenPinned = false;
        root.overviewScreenName = "";
    }

    Timer {
        id: previewExitTimerObject
        interval: root.previewAnimationDuration
        onTriggered: {
            root.previewExitToplevel = null;
            root.previewNavigationSlowMotion = false;
            if (!root.previewToplevel)
                root.previewSlowMotion = false;
        }
    }
}
