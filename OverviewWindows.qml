import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons as Commons
import qs.Ui as Ui
import "IconResolver.js" as IconResolver
import "WindowModel.js" as WindowModel
import "ScreenLayout.js" as ScreenLayout

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
                ratios[sessionIndex] = root.liveAspectRatioFor(top);
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
        var next = [];
        for (var index = 0; index < root.allToplevels.length; index++)
            if (WindowModel.isEligible(root.allToplevels[index]))
                next.push(root.allToplevels[index]);
        root.sessionToplevels = next;
        root.captureSessionAspectRatios();
        root.modelRevision++;
    }

    function syncSessionToplevels() {
        if (!root.surfaceMounted && !root.openingPending)
            return false;
        var current = [];
        for (var currentIndex = 0; currentIndex < root.allToplevels.length; currentIndex++)
            if (WindowModel.isEligible(root.allToplevels[currentIndex]))
                current.push(root.allToplevels[currentIndex]);

        var next = [];
        var nextRatios = [];
        for (var oldIndex = 0; oldIndex < root.sessionToplevels.length; oldIndex++) {
            var existing = root.sessionToplevels[oldIndex];
            if (current.indexOf(existing) === -1)
                continue;
            next.push(existing);
            nextRatios.push(root.sessionAspectRatios[oldIndex] || root.liveAspectRatioFor(existing));
        }
        for (var newIndex = 0; newIndex < current.length; newIndex++) {
            var candidate = current[newIndex];
            if (next.indexOf(candidate) !== -1)
                continue;
            next.push(candidate);
            nextRatios.push(root.liveAspectRatioFor(candidate));
        }

        var changed = next.length !== root.sessionToplevels.length;
        for (var compareIndex = 0; !changed && compareIndex < next.length; compareIndex++)
            changed = next[compareIndex] !== root.sessionToplevels[compareIndex];
        if (!changed)
            return false;
        root.sessionToplevels = next;
        root.sessionAspectRatios = nextRatios;
        root.modelRevision++;
        return true;
    }

    function captureSessionAspectRatios() {
        var ratios = [];
        for (var index = 0; index < root.sessionToplevels.length; index++)
            ratios.push(root.liveAspectRatioFor(root.sessionToplevels[index]));
        root.sessionAspectRatios = ratios;
    }

    function formatWorkspaceLabel(name) {
        return WindowModel.formatWorkspaceLabel(name, root.workspaceLabelStyle);
    }

    function workspaceName(top) {
        return root.formatWorkspaceLabel(WindowModel.workspaceName(top));
    }

    function workspaceLabel(top) {
        return "Workspace " + root.workspaceName(top);
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

    function isOnWorkspace(top, workspace) {
        return WindowModel.isOnWorkspace(top, workspace);
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
            if (root.workspaceScope === "current" && !root.isOnWorkspace(top, currentWorkspace))
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

    function liveAspectRatioFor(top) {
        return WindowModel.aspectRatioFor(top);
    }

    function aspectRatioFor(top) {
        if (root.surfaceMounted) {
            var index = root.sessionToplevels.indexOf(top);
            if (index >= 0 && root.sessionAspectRatios[index] > 0)
                return root.sessionAspectRatios[index];
        }
        return root.liveAspectRatioFor(top);
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
