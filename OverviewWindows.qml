import QtQuick
import Quickshell
import Quickshell.Hyprland
import "IconResolver.js" as IconResolver
import "WindowModel.js" as WindowModel

// Which windows the overview shows and how they are identified.
OverviewSettingsApi {
    id: root

    function setFilter(value) {
        root.filterText = value;
        root.hoveredToplevel = null;
        root.clearPreview();
        root.modelRevision++;
        root.selectedToplevel = root.filteredToplevels[0] || null;
    }

    function setWorkspaceScope(value) {
        var next = value === "current" ? "current" : "all";
        if (next === "current" && !root.workspaceForScreen(root.keyboardScreenName))
            return;
        if (next === root.workspaceScope)
            return;
        root.workspaceScope = next;
        root.hoveredToplevel = null;
        root.clearPreview();
        root.modelRevision++;
        root.selectedToplevel = root.originToplevel;
    }

    function toggleWorkspaceScope() {
        root.setWorkspaceScope(root.workspaceScope === "all" ? "current" : "all");
    }

    function refreshHyprlandState() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
    }

    function handleDisplayStateChanged() {
        if (!root.surfaceMounted && !root.openingPending)
            return;
        if (!root.overviewScreenPinned && (!root.surfaceMounted || root.openingPending))
            root.overviewScreenName = root.focusedMonitorName || root.keyboardScreenName;
        root.hoveredToplevel = null;
        root.clearPreview();
        root.modelRevision++;
    }

    function handleToplevelMetadataChanged(top) {
        if (!root.surfaceMounted && !root.openingPending)
            return;
        var membershipChanged = root.syncSessionToplevels();
        if (root.openingPending) {
            let sessionIndex = root.sessionToplevels.indexOf(top);
            if (sessionIndex >= 0) {
                let ratios = root.sessionAspectRatios.slice();
                ratios[sessionIndex] = WindowModel.aspectRatioFor(top);
                root.sessionAspectRatios = ratios;
            }
        }
        if (!membershipChanged)
            root.modelRevision++;
        root.clearUnlistedPreview();
    }

    function clearUnlistedPreview() {
        var listed = root.filteredToplevels;
        if ((root.previewToplevel && listed.indexOf(root.previewToplevel) === -1)
                || (root.previewExitToplevel && listed.indexOf(root.previewExitToplevel) === -1))
            root.clearPreview();
    }

    function handleToplevelCollectionChanged() {
        if (!root.surfaceMounted && !root.openingPending)
            return;
        var membershipChanged = root.syncSessionToplevels();
        if (!membershipChanged && root.filterText.length > 0)
            root.modelRevision++;
        root.clearUnlistedPreview();
    }

    function activate(top) {
        if (!top)
            return;
        root.pendingActivation = top;
        root.dismiss();
    }

    // Runs once the overlay surface is gone: Hyprland returns focus to the
    // previous window when an exclusive-keyboard layer unmaps, which would
    // override a focus requested earlier.
    function dispatchPendingActivation() {
        var address = WindowModel.addressFor(root.pendingActivation);
        root.pendingActivation = null;
        if (!address)
            return;
        var focus = "hl.dispatch(hl.dsp.focus({ window = 'address:" + address + "' }))";
        Hyprland.dispatch(root.moveCursorToWindow
            ? "(function() " + focus + " end)"
            : "(function() local p = hl.get_cursor_pos(); " + focus
                + "; hl.dispatch(hl.dsp.cursor.move({ x = p.x, y = p.y })) end)");
    }

    function requestClose(top) {
        var wayland = WindowModel.waylandFor(top);
        if (!wayland || typeof wayland.close !== "function")
            return;
        wayland.close();
    }

    function resetSessionToplevels() {
        root.sessionToplevels = root.eligibleToplevels();
        root.sessionAspectRatios = root.sessionToplevels.map(top => WindowModel.aspectRatioFor(top));
        root.modelRevision++;
    }

    function eligibleToplevels() {
        return root.allToplevels.filter(top => WindowModel.isEligible(top));
    }

    function syncSessionToplevels() {
        if (!root.surfaceMounted && !root.openingPending)
            return false;
        var current = root.eligibleToplevels();

        var next = [];
        var nextRatios = [];
        for (let oldIndex = 0; oldIndex < root.sessionToplevels.length; oldIndex++) {
            let existing = root.sessionToplevels[oldIndex];
            if (current.indexOf(existing) === -1)
                continue;
            next.push(existing);
            nextRatios.push(root.sessionAspectRatios[oldIndex] || WindowModel.aspectRatioFor(existing));
        }
        for (let newIndex = 0; newIndex < current.length; newIndex++) {
            let candidate = current[newIndex];
            if (next.indexOf(candidate) !== -1)
                continue;
            next.push(candidate);
            nextRatios.push(WindowModel.aspectRatioFor(candidate));
        }

        if (root.toplevelListsEqual(next, root.sessionToplevels))
            return false;
        root.sessionToplevels = next;
        root.sessionAspectRatios = nextRatios;
        root.modelRevision++;
        return true;
    }

    function formatWorkspaceLabel(name) {
        return WindowModel.formatWorkspaceLabel(name, root.workspaceLabelStyle);
    }

    function workspaceName(top) {
        return root.formatWorkspaceLabel(WindowModel.workspaceName(top));
    }

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

    function activeWorkspaceLabelForScreen(screenName) {
        var workspace = root.workspaceForScreen(screenName);
        if (!workspace)
            return "—";
        return root.formatWorkspaceLabel(String(workspace.name || workspace.id || "—"));
    }

    function workspaceScopeLabelForScreen(screenName) {
        return root.workspaceScope === "current"
            ? "Workspace " + root.activeWorkspaceLabelForScreen(screenName)
            : "All workspaces";
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

    function toplevelListsEqual(left, right) {
        if (left.length !== right.length)
            return false;
        for (let index = 0; index < left.length; index++)
            if (left[index] !== right[index])
                return false;
        return true;
    }

    function aspectRatioFor(top) {
        if (root.surfaceMounted) {
            let index = root.sessionToplevels.indexOf(top);
            if (index >= 0 && root.sessionAspectRatios[index] > 0)
                return root.sessionAspectRatios[index];
        }
        return WindowModel.aspectRatioFor(top);
    }

    function iconFor(top) {
        var identity = IconResolver.identityFor(top);
        if (Object.prototype.hasOwnProperty.call(root.iconCache, identity.key))
            return root.iconCache[identity.key];
        var entries = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        var entry = IconResolver.findEntry(entries, identity.candidates);
        var iconName = entry
            ? String(entry.icon || "application-x-executable")
            : String(identity.candidates[0] || "application-x-executable");
        var appLibrary = root.shell && root.shell.appLibrary ? root.shell.appLibrary : null;
        var result = appLibrary && typeof appLibrary.iconSource === "function"
            ? String(appLibrary.iconSource(iconName) || "")
            : "";
        if (!result)
            result = Quickshell.iconPath(iconName, true);
        root.iconCache[identity.key] = result;
        return result;
    }
}
