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
        root.selectedIndex = 0;
        root.hoveredIndex = -1;
        root.clearPreview();
        root.modelRevision++;
    }

    function setWorkspaceScope(value) {
        var next = value === "current" ? "current" : "all";
        if (next === "current" && !root.workspaceForScreen(root.keyboardScreenName))
            return;
        if (next === root.workspaceScope)
            return;
        root.workspaceScope = next;
        root.hoveredIndex = -1;
        root.clearPreview();
        root.modelRevision++;
        root.selectedIndex = Math.max(0, root.filteredToplevels.indexOf(Hyprland.activeToplevel));
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
        var selectedTop = root.filteredToplevels[root.selectedIndex];
        root.hoveredIndex = -1;
        root.clearPreview();
        root.modelRevision++;
        var nextIndex = root.filteredToplevels.indexOf(selectedTop);
        root.selectedIndex = nextIndex >= 0 ? nextIndex : Math.max(0, root.filteredToplevels.indexOf(Hyprland.activeToplevel));
    }

    function handleToplevelMetadataChanged(top) {
        if (!root.surfaceMounted && !root.openingPending)
            return;
        var selectedTop = root.filteredToplevels[root.selectedIndex];
        var previewTop = root.previewIndex >= 0 ? root.filteredToplevels[root.previewIndex] : null;
        var previewExitTop = root.previewExitIndex >= 0 ? root.filteredToplevels[root.previewExitIndex] : null;
        var membershipChanged = root.syncSessionToplevels();
        if (root.openingPending) {
            var sessionIndex = root.sessionToplevels.indexOf(top);
            if (sessionIndex >= 0) {
                var ratios = root.sessionAspectRatios.slice();
                ratios[sessionIndex] = WindowModel.aspectRatioFor(top);
                root.sessionAspectRatios = ratios;
            }
        }
        if (!membershipChanged)
            root.modelRevision++;

        var selectedIndex = root.filteredToplevels.indexOf(selectedTop);
        if (selectedIndex < 0)
            selectedIndex = root.filteredToplevels.indexOf(Hyprland.activeToplevel);
        root.selectedIndex = Math.max(0, selectedIndex);

        if (previewTop) {
            var previewIndex = root.filteredToplevels.indexOf(previewTop);
            if (previewIndex < 0)
                root.clearPreview();
            else
                root.previewIndex = previewIndex;
        } else if (previewExitTop) {
            var previewExitIndex = root.filteredToplevels.indexOf(previewExitTop);
            if (previewExitIndex < 0)
                root.clearPreview();
            else
                root.previewExitIndex = previewExitIndex;
        }
    }

    function handleToplevelCollectionChanged() {
        if (!root.surfaceMounted && !root.openingPending)
            return;
        var membershipChanged = root.syncSessionToplevels();
        var filteredMembershipMayChange = !membershipChanged && root.filterText.length > 0;
        if ((membershipChanged || filteredMembershipMayChange)
                && (root.previewIndex >= 0 || root.previewExitIndex >= 0))
            root.clearPreview();
        if (filteredMembershipMayChange)
            root.modelRevision++;
        if (root.selectedIndex >= root.filteredToplevels.length)
            root.selectedIndex = Math.max(0, root.filteredToplevels.length - 1);
        if (root.previewIndex >= root.filteredToplevels.length)
            root.clearPreview();
    }

    function activate(top) {
        if (!top)
            return;
        var helper = root.pluginDir + "/activate-window";
        Quickshell.execDetached([
            helper,
            WindowModel.addressFor(top),
            WindowModel.appIdFor(top),
            String(top.title || ""),
            root.moveCursorToWindow ? "true" : "false"
        ]);
        root.dismiss();
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
        for (var oldIndex = 0; oldIndex < root.sessionToplevels.length; oldIndex++) {
            var existing = root.sessionToplevels[oldIndex];
            if (current.indexOf(existing) === -1)
                continue;
            next.push(existing);
            nextRatios.push(root.sessionAspectRatios[oldIndex] || WindowModel.aspectRatioFor(existing));
        }
        for (var newIndex = 0; newIndex < current.length; newIndex++) {
            var candidate = current[newIndex];
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
        for (var index = 0; index < monitors.length; index++) {
            var monitor = monitors[index];
            if (monitor && monitor.name === wanted)
                return monitor;
        }
        return null;
    }

    function workspaceForScreen(screenName) {
        if (root.multiMonitorMode === "per-monitor") {
            var monitor = root.monitorForScreen(screenName);
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
        for (var index = 0; index < source.length; index++) {
            var top = source[index];
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
        for (var index = 0; index < candidates.length; index++) {
            var top = candidates[index];
            if (root.workspaceScope === "current" && !WindowModel.isOnWorkspace(top, currentWorkspace))
                continue;
            var haystack = WindowModel.searchTextFor(top);
            if (!needle || haystack.indexOf(needle) !== -1)
                result.push(top);
        }
        return result;
    }

    function toplevelListsEqual(left, right) {
        if (left.length !== right.length)
            return false;
        for (var index = 0; index < left.length; index++)
            if (left[index] !== right[index])
                return false;
        return true;
    }

    function aspectRatioFor(top) {
        if (root.surfaceMounted) {
            var index = root.sessionToplevels.indexOf(top);
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
