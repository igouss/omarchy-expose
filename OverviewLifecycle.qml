import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons as Commons

// Opening, dismissing, the background blur session, and overview keys.
OverviewLayout {
    id: root

    // The entry layer owns the surfaces and the hot corner, and answers these.
    // Asks for keyboard focus wherever it belongs now: the settings when they
    // are open, the window grid otherwise. One request, so a late one from the
    // open sequence cannot pull focus out of settings.
    signal focusRequested()
    signal surfaceReleased()
    // A window is being activated; sent only while activation punch is on.
    signal activating(var top)

    onEffectiveBackgroundBlurChanged: {
        if (!root.surfaceMounted)
            return;
        if (!backgroundBlurSession.running && root.effectiveBackgroundBlur > 0 && !root.backgroundBlurFailed) {
            root.backgroundBlurPrimed = false;
            backgroundBlurSession.running = true;
        } else {
            root.scheduleBackgroundBlurUpdate();
        }
    }

    function open() {
        // A reopen during the activation punch cancels that activation.
        if (punchHold.running) {
            punchHold.stop();
            root.pendingActivation = null;
        }
        // Taken before the overlay takes keyboard focus, which can clear the active window.
        root.originToplevel = Hyprland.activeToplevel;
        windowBorders.refresh();
        var blurRestoreInFlight = root.backgroundBlurReleasePhase === 1 && backgroundBlurSession.running;
        if (!blurRestoreInFlight)
            root.backgroundBlurReleasePhase = 0;
        root.closeSettings();
        root.filterText = "";
        root.workspaceScope = root.initialWorkspaceScope;
        root.dismissNotifyShell = false;
        if (root.surfaceMounted) {
            if (blurRestoreInFlight) {
                root.openingPending = true;
                return;
            }
            root.opened = true;
            root.animateMotionTo(1);
            root.refreshHyprlandState();
            Qt.callLater(root.focusRequested);
            return;
        }
        if (root.openingPending)
            return;
        if (!root.overviewScreenPinned)
            root.overviewScreenName = root.keyboardScreenName;
        overviewMotionAnimation.stop();
        root.motionTarget = 0;
        root.motionProgress = 0;
        root.openingPending = true;
        root.refreshHyprlandState();
        root.resetSessionToplevels();
        root.selectedToplevel = root.originToplevel;
        root.hoveredToplevel = null;
        root.clearPreview();
        root.backgroundBlurPrimed = false;
        root.backgroundBlurFailed = false;
        if (root.effectiveBackgroundBlur > 0) {
            if (!blurRestoreInFlight)
                backgroundBlurSession.running = true;
        } else {
            root.prepareOpenSurface();
        }
    }

    function close() {
        root.startDismiss(false);
    }

    function startDismiss(notifyShell) {
        root.openingPending = false;
        root.closeSettings();
        root.hoveredToplevel = null;
        root.clearPreview();
        root.opened = false;
        root.dismissNotifyShell = root.dismissNotifyShell || notifyShell;
        if (root.backgroundBlurReleasePhase > 0)
            return;
        if (root.surfaceMounted) {
            root.animateMotionTo(0);
            return;
        }
        overviewMotionAnimation.stop();
        root.motionTarget = 0;
        root.motionProgress = 0;
        root.backgroundBlurPrimed = false;
        root.backgroundBlurReleasePhase = 0;
        backgroundBlurSession.running = false;
        root.clearOverviewScreen();
        root.finishDismiss();
    }

    function dismiss() {
        root.startDismiss(true);
    }

    function toggle() {
        (root.opened || root.openingPending) ? root.dismiss() : root.open();
    }

    function requestedBackgroundBlur() {
        return Math.max(0, Math.round(root.effectiveBackgroundBlur));
    }

    function writeBackgroundBlur(size) {
        backgroundBlurSession.write(String(size) + "\n");
    }

    function scheduleBackgroundBlurUpdate() {
        if (backgroundBlurSession.running && !backgroundBlurUpdate.running)
            backgroundBlurUpdate.start();
    }

    function prepareOpenSurface() {
        if (!root.openingPending)
            return;
        if (root.effectiveBackgroundBlur > 0 && !root.backgroundBlurFailed) {
            if (!backgroundBlurSession.running) {
                root.backgroundBlurPrimed = false;
                backgroundBlurSession.running = true;
                return;
            }
            if (!root.backgroundBlurPrimed)
                return;
        }
        if (!root.overviewScreenPinned)
            root.overviewScreenName = root.focusedMonitorName || root.keyboardScreenName;
        root.surfaceMounted = true;
        Qt.callLater(function () {
            if (!root.surfaceMounted || !root.openingPending)
                return;
            root.openingPending = false;
            root.opened = true;
            root.animateMotionTo(1);
            root.focusRequested();
        });
    }

    function animateMotionTo(target) {
        var next = target >= 0.5 ? 1 : 0;
        overviewMotionAnimation.stop();
        root.motionTarget = next;
        var distance = Math.abs(next - root.motionProgress);
        if (distance < 0.001) {
            root.motionProgress = next;
            root.completeMotion();
            return;
        }
        if (root.motionProgress <= 0.001 || root.motionProgress >= 0.999)
            root.slideMotionDirection = String(root.slideDirection[next > 0 ? "in" : "out"]);
        overviewMotionAnimation.from = root.motionProgress;
        overviewMotionAnimation.to = next;
        var configuredDuration = next > root.motionProgress
            ? root.animationInDurationFor(root.animationStyle)
            : root.animationOutDurationFor(root.animationStyle);
        overviewMotionAnimation.duration = Math.max(1, Math.round(configuredDuration * distance));
        overviewMotionAnimation.easing.type = root.animationStyle === "original"
            ? Easing.OutQuart
            : (next > root.motionProgress ? Easing.OutCubic : Easing.InCubic);
        overviewMotionAnimation.start();
    }

    function previewAnimation() {
        if (!root.surfaceMounted)
            return;
        overviewMotionAnimation.stop();
        root.motionTarget = 1;
        root.motionProgress = 0;
        root.animateMotionTo(1);
    }

    function completeMotion() {
        root.motionProgress = root.motionTarget;
        if (root.motionTarget > 0) {
            root.scheduleBackgroundBlurUpdate();
            Qt.callLater(root.focusRequested);
            return;
        }
        backgroundBlurUpdate.stop();
        if (backgroundBlurSession.running) {
            root.backgroundBlurReleasePhase = 1;
            root.backgroundBlurPrimed = false;
            backgroundBlurSession.write("close\n");
            return;
        }
        root.releaseBlurredSurface();
    }

    function releaseBlurredSurface() {
        root.surfaceMounted = false;
        root.backgroundBlurPrimed = false;
        root.clearOverviewScreen();
        root.backgroundBlurReleasePhase = 0;
        root.finishDismiss();
        root.surfaceReleased();
    }

    function activate(top) {
        if (!top)
            return;
        root.pendingActivation = top;
        if (!root.juicePunch) {
            root.dismiss();
            return;
        }
        // Activation punch plays on the open overlay; closing at once would hide it.
        root.activating(top);
        punchHold.restart();
    }

    function finishDismiss() {
        if (root.pendingActivation)
            root.dispatchPendingActivation();
        var notifyShell = root.dismissNotifyShell;
        root.dismissNotifyShell = false;
        if (notifyShell && root.shell && typeof root.shell.hide === "function")
            root.shell.hide(root.pluginId);
    }

    function openSettings() {
        if (!root.surfaceMounted)
            root.open();
        root.closeFooterHideConfirmation();
        root.clearSettingsPreviews();
        root.settingsCategoryIndex = 0;
        root.settingsOpen = true;
        Qt.callLater(root.focusRequested);
    }

    function closeSettings() {
        var restoreKeyboardFocus = root.settingsOpen && root.opened;
        root.closeFooterHideConfirmation();
        root.settingsOpen = false;
        root.clearSettingsPreviews();
        if (restoreKeyboardFocus)
            Qt.callLater(function () {
                if (root.opened)
                    root.focusRequested();
            });
    }

    Timer {
        id: punchHold
        interval: 180
        onTriggered: {
            if (root.opened)
                root.dismiss();
        }
    }

    NumberAnimation {
        id: overviewMotionAnimation
        target: root
        property: "motionProgress"
        onFinished: root.completeMotion()
    }

    Timer {
        id: backgroundBlurUpdate
        interval: 16
        onTriggered: {
            if (!backgroundBlurSession.running)
                return;
            var requested = root.requestedBackgroundBlur();
            if (requested === root.lastRequestedBlur)
                return;
            root.lastRequestedBlur = requested;
            root.writeBackgroundBlur(requested);
        }
    }

    Process {
        id: backgroundBlurSession
        command: [root.pluginDir + "/background-blur-session"]
        stdinEnabled: true
        onStarted: {
            var initialBlur = root.requestedBackgroundBlur();
            root.lastRequestedBlur = initialBlur;
            root.writeBackgroundBlur(initialBlur);
        }
        stdout: SplitParser {
            onRead: function (line) {
                var applied = Number(line);
                if (!isFinite(applied))
                    return;
                if (applied < 0) {
                    if (root.backgroundBlurReleasePhase > 0) {
                        root.backgroundBlurReleasePhase = 0;
                        backgroundBlurSession.running = false;
                        if (root.surfaceMounted) {
                            root.surfaceMounted = false;
                            root.backgroundBlurPrimed = false;
                            root.clearOverviewScreen();
                        }
                        if (root.openingPending) {
                            root.backgroundBlurFailed = true;
                            root.prepareOpenSurface();
                        } else {
                            root.finishDismiss();
                        }
                        return;
                    }
                    root.backgroundBlurFailed = true;
                    root.prepareOpenSurface();
                    return;
                }
                if (applied === 0 && root.backgroundBlurReleasePhase === 1) {
                    root.backgroundBlurReleasePhase = 0;
                    if (root.openingPending) {
                        root.lastRequestedBlur = root.requestedBackgroundBlur();
                        root.writeBackgroundBlur(root.lastRequestedBlur);
                    } else {
                        backgroundBlurSession.running = false;
                        root.releaseBlurredSurface();
                    }
                    return;
                }
                if (root.openingPending) {
                    root.backgroundBlurReleasePhase = 0;
                    root.backgroundBlurPrimed = true;
                    root.prepareOpenSurface();
                }
            }
        }
        onExited: function (exitCode, exitStatus) {
            root.backgroundBlurPrimed = false;
            root.lastRequestedBlur = -1;
            if (root.backgroundBlurReleasePhase > 0) {
                root.backgroundBlurReleasePhase = 0;
                if (root.surfaceMounted) {
                    root.surfaceMounted = false;
                    root.clearOverviewScreen();
                }
                if (!root.surfaceMounted && !root.openingPending)
                    root.finishDismiss();
            }
            if (root.openingPending) {
                root.backgroundBlurFailed = true;
                root.prepareOpenSurface();
            }
        }
    }

    function handleKey(event, layout) {
        if (root.settingsOpen) {
            if (event.key === Qt.Key_Escape) {
                if (root.footerHideConfirmationOpen)
                    root.closeFooterHideConfirmation();
                else
                    root.closeSettings();
                event.accepted = true;
            } else {
                event.accepted = false;
            }
            return;
        }
        if (event.key === Qt.Key_Escape) {
            if (root.previewToplevel || root.previewExitToplevel)
                root.clearPreview();
            else
                root.dismiss();
        } else if (event.key === Qt.Key_Space || event.text === " ") {
            if (!event.isAutoRepeat)
                root.togglePreview(Boolean(event.modifiers & Qt.ShiftModifier));
        }
        else if (event.key === Qt.Key_Tab
                && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            if (!event.isAutoRepeat)
                root.toggleWorkspaceScope();
        }
        else if (event.key === Qt.Key_Left)
            root.moveDirectional(-1, 0, layout, Boolean(event.modifiers & Qt.ShiftModifier));
        else if (event.key === Qt.Key_Right)
            root.moveDirectional(1, 0, layout, Boolean(event.modifiers & Qt.ShiftModifier));
        else if (event.key === Qt.Key_Up)
            root.moveDirectional(0, -1, layout, Boolean(event.modifiers & Qt.ShiftModifier));
        else if (event.key === Qt.Key_Down)
            root.moveDirectional(0, 1, layout, Boolean(event.modifiers & Qt.ShiftModifier));
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            root.activate(root.selection);
        else if (event.key === Qt.Key_Q
                && Boolean(event.modifiers & Qt.ShiftModifier)
                && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            if (!event.isAutoRepeat)
                root.requestClose(root.selection);
        }
        else if (Commons.Util.editsFilter(event, root.filterText))
            root.setFilter(Commons.Util.editedFilter(event, root.filterText));
        else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32 && !(event.modifiers & (Qt.AltModifier | Qt.MetaModifier)))
            root.setFilter(root.filterText + event.text);
        else
            return;
        event.accepted = true;
    }
}
