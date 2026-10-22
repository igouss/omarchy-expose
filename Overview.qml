import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons // qmllint disable import
import qs.Ui as Ui // qmllint disable import
import "IconResolver.js" as IconResolver
import "WindowModel.js" as WindowModel
import "ScreenLayout.js" as ScreenLayout

// Exposé entry point: surfaces, compositor wiring, and the hot corner.
OverviewLifecycle {
    id: root

    onHotCornerScreensChanged: root.scheduleHotCornerRearm()

    readonly property var overviewKeyboardTargets: surfaceInstances.instances.length
        ? surfaceInstances.instances[0].keyboardTargets
        : []

    onMultiMonitorModeChanged: {
        root.hoveredIndex = -1;
        root.clearPreview();
        root.modelRevision++;
        root.selectedIndex = Math.max(0, root.filteredToplevels.indexOf(Hyprland.activeToplevel));
    }

    function hotCornerHovered() {
        var groups = [hotCornerInstances, surfaceInstances, backdropInstances];
        for (var groupIndex = 0; groupIndex < groups.length; groupIndex++) {
            var instances = groups[groupIndex].instances;
            for (var index = 0; index < instances.length; index++)
                if (instances[index] && instances[index].hotCornerHovered)
                    return true;
        }
        return false;
    }

    function triggerHotCorner(screenName) {
        if (!root.hotCornerEnabled || !root.hotCornerArmed)
            return;
        root.hotCornerArmed = false;
        if (root.opened || root.openingPending) {
            root.dismiss();
            return;
        }
        var name = String(screenName || "");
        if (name) {
            root.overviewScreenPinned = true;
            root.overviewScreenName = name;
        }
        root.open("{}");
    }

    function scheduleHotCornerRearm() {
        hotCornerRearm.restart();
    }

    onHotCornerEnabledChanged: {
        if (!root.hotCornerEnabled) {
            hotCornerRearm.stop();
            root.hotCornerArmed = true;
        }
    }

    function focusKeyboardWindow() {
        for (var i = 0; i < surfaceInstances.instances.length; i++) {
            var surface = surfaceInstances.instances[i];
            if (surface && surface.acceptsKeyboard) {
                surface.keyboardItem.forceActiveFocus();
                return;
            }
        }
    }

    function focusSettingsCategory() {
        for (var i = 0; i < surfaceInstances.instances.length; i++) {
            var surface = surfaceInstances.instances[i];
            if (surface && surface.acceptsKeyboard) {
                surface.focusSettingsCategory();
                return;
            }
        }
    }

    function focusSettingsItem(item) {
        if (!item || !item.visible || !item.enabled)
            return false;
        item.forceActiveFocus();
        return true;
    }

    // Tab/Shift+Tab wrap through every focusable item. Up/Down (and Left/Right
    // inside the confirmation dialog) step without wrapping, so arrow keys never
    // jump from the last control back to the sidebar.
    function handleSettingsNavigation(event) {
        if (!root.settingsOpen)
            return false;
        var isTab = event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab;
        var isStep = event.key === Qt.Key_Up || event.key === Qt.Key_Down
            || (root.footerHideConfirmationOpen && (event.key === Qt.Key_Left || event.key === Qt.Key_Right));
        if (!isTab && !isStep)
            return false;
        var forward = isTab
            ? event.key !== Qt.Key_Backtab && !(event.modifiers & Qt.ShiftModifier)
            : event.key === Qt.Key_Down || event.key === Qt.Key_Right;
        for (var index = 0; index < surfaceInstances.instances.length; index++) {
            var surface = surfaceInstances.instances[index];
            if (!surface || !surface.acceptsKeyboard)
                continue;
            if (root.footerHideConfirmationOpen)
                surface.moveFooterConfirmationFocus(forward, isTab);
            else
                surface.moveSettingsFocus(forward, isTab);
            event.accepted = true;
            return true;
        }
        return false;
    }

    function handleSettingsTab(event) {
        if (event.key !== Qt.Key_Tab && event.key !== Qt.Key_Backtab)
            return false;
        return root.handleSettingsNavigation(event);
    }

    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { root.handleToplevelCollectionChanged(); }
    }

    Instantiator {
        model: Hyprland.toplevels

        delegate: Connections {
            required property var modelData
            target: modelData
            function onWorkspaceChanged() { root.handleDisplayStateChanged(); }
            function onMonitorChanged() { root.handleDisplayStateChanged(); }
            function onLastIpcObjectChanged() { root.handleToplevelMetadataChanged(modelData); }
            function onWaylandHandleChanged() { root.handleToplevelCollectionChanged(); }
        }
    }

    Instantiator {
        model: Hyprland.monitors

        delegate: Connections {
            required property var modelData
            target: modelData
            function onActiveWorkspaceChanged() { root.handleDisplayStateChanged(); }
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.iconCache = {};
        }
    }

    Connections {
        target: root.shell && root.shell.appLibrary ? root.shell.appLibrary : null
        function onIconIndexChanged() { root.iconCache = {}; }
    }

    Timer {
        id: hotCornerRearm
        interval: 100
        onTriggered: {
            if (!root.hotCornerHovered())
                root.hotCornerArmed = true;
        }
    }

    // Let compositor keybinds reach the resident shell without spawning a CLI.
    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() { root.handleDisplayStateChanged(); }
        function onFocusedWorkspaceChanged() { root.handleDisplayStateChanged(); }
        function onActiveToplevelChanged() {
            if (!root.opened)
                return;
            var index = root.filteredToplevels.indexOf(Hyprland.activeToplevel);
            if (index >= 0)
                root.selectedIndex = index;
        }
        function onRawEvent(event) {
            if (event && event.name === "configreloaded")
                windowBorders.refresh();
            if (event && event.name === "custom" && event.data === "expose.window-overview:toggle")
                root.toggle();
        }
    }

    OverviewIpc { overview: root }

    component HotCornerTarget: Item {
        id: cornerTarget
        required property bool onTop
        required property bool onLeft
        readonly property bool hovered: enabled && (horizontalTarget.containsMouse || verticalTarget.containsMouse)
        signal entered()
        signal exited()

        implicitWidth: root.hotCornerReach
        implicitHeight: root.hotCornerReach

        // The two strips overlap in the corner square, so hovering is tracked
        // across both: sliding from one into the other must not restart the
        // dwell or report a spurious exit.
        onHoveredChanged: {
            if (cornerTarget.hovered) {
                if (root.effectiveHotCornerDelay > 0)
                    dwellTimer.restart();
                else
                    cornerTarget.entered();
            } else {
                dwellTimer.stop();
                cornerTarget.exited();
            }
        }

        Timer {
            id: dwellTimer
            interval: root.effectiveHotCornerDelay
            onTriggered: {
                if (cornerTarget.hovered)
                    cornerTarget.entered();
            }
        }

        MouseArea {
            id: horizontalTarget
            x: 0
            y: cornerTarget.onTop ? 0 : parent.height - height
            width: parent.width
            height: root.hotCornerDepth
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        MouseArea {
            id: verticalTarget
            x: cornerTarget.onLeft ? 0 : parent.width - width
            y: 0
            width: root.hotCornerDepth
            height: parent.height
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    // Full-screen surfaces take over corner handling while Exposé is mounted.
    Variants {
        id: hotCornerInstances
        model: root.hotCornerScreens

        PanelWindow { // qmllint disable uncreatable-type
            required property var modelData
            screen: modelData
            visible: !root.surfaceMounted
            anchors {
                top: root.hotCornerOnTop
                right: !root.hotCornerOnLeft
                bottom: !root.hotCornerOnTop
                left: root.hotCornerOnLeft
            }
            implicitWidth: root.hotCornerReach
            implicitHeight: root.hotCornerReach
            color: "#02000000"
            mask: Region {
                Region {
                    x: 0
                    y: root.hotCornerOnTop ? 0 : root.hotCornerReach - root.hotCornerDepth
                    width: root.hotCornerReach
                    height: root.hotCornerDepth
                }
                Region {
                    x: root.hotCornerOnLeft ? 0 : root.hotCornerReach - root.hotCornerDepth
                    y: 0
                    width: root.hotCornerDepth
                    height: root.hotCornerReach
                }
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "expose-hot-corner"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            readonly property bool hotCornerHovered: closedHotCorner.hovered

            HotCornerTarget {
                id: closedHotCorner
                anchors.fill: parent
                enabled: !root.surfaceMounted
                onTop: root.hotCornerOnTop
                onLeft: root.hotCornerOnLeft
                onEntered: root.triggerHotCorner(String(modelData.name || ""))
                onExited: root.scheduleHotCornerRearm()
            }
        }
    }

    component OverviewSurface: PanelWindow { // qmllint disable uncreatable-type
        id: surface
        required property var modelData
        screen: modelData
        visible: true
        anchors {
            top: true
            right: true
            bottom: true
            left: true
        }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "expose-window-overview"
        WlrLayershell.layer: WlrLayer.Overlay
        // Hyprland restricts pointer hit testing to exclusive surfaces too.
        // Every backdrop must participate so clicks on other displays arrive.
        WlrLayershell.keyboardFocus: root.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        HyprlandWindow.opacity: root.motionProgress
        BackgroundEffect.blurRegion: root.effectiveBackgroundBlur > 0 // qmllint disable missing-type
                && !root.backgroundBlurFailed
            ? backgroundBlurRegion
            : null
        readonly property bool hotCornerHovered: openHotCorner.hovered

        Region {
            id: backgroundBlurRegion
            item: surface.contentItem
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.effectiveBackgroundDim / 100
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {
                if (surface.modelData === root.effectiveOverviewScreen
                        && (root.previewIndex >= 0 || root.previewExitIndex >= 0))
                    root.clearPreview();
                else
                    root.dismiss();
            }
            onWheel: function (wheel) { wheel.accepted = true; }
        }

        HotCornerTarget {
            id: openHotCorner
            width: root.hotCornerReach
            height: root.hotCornerReach
            x: root.hotCornerOnLeft ? 0 : parent.width - width
            y: root.hotCornerOnTop ? 0 : parent.height - height
            z: 100
            enabled: root.surfaceMounted && root.hotCornerScreens.indexOf(surface.modelData) !== -1
            onTop: root.hotCornerOnTop
            onLeft: root.hotCornerOnLeft
            onEntered: root.triggerHotCorner(String(surface.modelData.name || ""))
            onExited: root.scheduleHotCornerRearm()
        }
    }

    Variants {
        id: backdropInstances
        model: root.backdropScreens
        OverviewSurface {
            Item {
                anchors.fill: parent
                focus: true
                Keys.forwardTo: root.opened ? root.overviewKeyboardTargets : []
            }
        }
    }

    Variants {
        id: surfaceInstances
        model: root.mountedScreens

        OverviewSurface {
            id: overviewWindow
            readonly property bool acceptsKeyboard: {
                var wanted = root.effectiveOverviewScreenName;
                if (wanted)
                    return String(modelData.name || "") === wanted;
                return true;
            }
            property alias keyboardItem: keyCatcher
            // Forwarded events don't bubble through the target's parents.
            // Run overview shortcuts first, then the focused settings control.
            readonly property var keyboardTargets: {
                var focused = keyCatcher.Window.window ? keyCatcher.Window.window.activeFocusItem : null;
                return focused && focused !== keyCatcher ? [keyCatcher, focused] : [keyCatcher];
            }
            readonly property var screenToplevels: {
                var revision = root.modelRevision;
                return root.toplevelsForScreen(String(modelData.name || ""));
            }
            // A Repeater over a JS array rebuilds every delegate when the array
            // is reassigned, and with it every screencopy capture and layer
            // texture. Cards are therefore created from every window on this
            // screen and only hidden by the filter, and the list is reassigned
            // solely when its membership changes.
            readonly property var cardToplevelsSource: {
                var revision = root.modelRevision;
                return root.toplevelsOnScreen(String(modelData.name || ""));
            }
            property var cardToplevels: []

            function syncCardToplevels() {
                if (!root.toplevelListsEqual(overviewWindow.cardToplevels, overviewWindow.cardToplevelsSource))
                    overviewWindow.cardToplevels = overviewWindow.cardToplevelsSource;
            }

            onCardToplevelsSourceChanged: overviewWindow.syncCardToplevels()
            Component.onCompleted: overviewWindow.syncCardToplevels()
            readonly property string screenWorkspaceLabel: root.activeWorkspaceLabelForScreen(String(modelData.name || ""))
            readonly property string screenScopeLabel: root.workspaceScopeLabelForScreen(String(modelData.name || ""))

            function focusSettingsCategory() {
                var settings = keyCatcher.settingsLayer.item;
                if (settings)
                    settings.focusSettingsCategory(); // qmllint disable missing-property
            }

            function moveSettingsFocus(forward, wrap) {
                var settings = keyCatcher.settingsLayer.item;
                if (settings)
                    settings.moveSettingsFocus(forward, wrap); // qmllint disable missing-property
            }

            function focusFirstSettingsControl() {
                var settings = keyCatcher.settingsLayer.item;
                if (settings)
                    settings.focusFirstSettingsControl(); // qmllint disable missing-property
            }

            function moveFooterConfirmationFocus(forward, wrap) {
                var settings = keyCatcher.settingsLayer.item;
                if (settings)
                    settings.moveFooterConfirmationFocus(forward, wrap); // qmllint disable missing-property
            }

            onAcceptsKeyboardChanged: {
                if (acceptsKeyboard && root.settingsOpen)
                    Qt.callLater(overviewWindow.focusSettingsCategory);
            }

            OverviewCanvas {
                id: keyCatcher
                overview: root
                screenWindow: overviewWindow
            }
        }
    }
}
