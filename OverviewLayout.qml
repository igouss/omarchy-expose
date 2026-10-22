import QtQuick
import "GridLayout.js" as GridLayout

// Card placement, Quick Look, and directional selection.
OverviewWindows {
    id: root

    // An arrow found no window that way; sent only while edge bump is on.
    signal edgeBumped(int dx, int dy)

    function computeWindowLayout(toplevels, width, height, gap, padding, footerHeight, viewportRatioHint) {
        return GridLayout.computeLayout(toplevels.map(top => root.aspectRatioFor(top)),
            width, height, gap, padding, footerHeight, viewportRatioHint);
    }

    function previewRectFor(top, sourceRect, width, height, padding, footerHeight) {
        return GridLayout.previewRect(root.aspectRatioFor(top), root.previewPlacement === "centered",
            sourceRect, width, height, padding, footerHeight);
    }

    function moveDirectional(dx, dy, layout, slowMotion) {
        var currentIndex = root.filteredToplevels.indexOf(root.selection);
        var bestIndex = GridLayout.neighbourIndex(layout, currentIndex, dx, dy);
        if (bestIndex < 0) {
            if (root.juiceEdgeBump && root.selection)
                root.edgeBumped(dx, dy);
            return;
        }

        var previousPreview = root.previewToplevel;
        var next = root.filteredToplevels[bestIndex];
        root.selectedToplevel = next;
        if (previousPreview) {
            root.previewSlowMotion = false;
            root.previewNavigationSlowMotion = slowMotion === true;
            previewExitTimer.stop();
            root.previewExitToplevel = previousPreview;
            root.previewToplevel = next;
            previewExitTimer.restart();
        }
    }

    function togglePreview(slowMotion) {
        root.previewNavigationSlowMotion = false;
        root.previewSlowMotion = slowMotion === true;
        if (root.previewToplevel) {
            root.previewExitToplevel = root.previewToplevel;
            root.previewToplevel = null;
            previewExitTimer.restart();
            return;
        }
        previewExitTimer.stop();
        root.previewExitToplevel = null;
        var target = root.hoveredToplevel || root.selection;
        if (target && root.filteredToplevels.indexOf(target) !== -1) {
            root.selectedToplevel = target;
            root.previewToplevel = target;
        }
    }
}
