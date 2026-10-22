import QtQuick
import qs.Commons as Commons

// The grid look: cards packed into balanced rows by GridLayout.js, each with
// a live preview.
Look {
    id: look

    windowLayout: {
        var revision = overview.modelRevision;
        return overview.computeWindowLayout(screenWindow.screenToplevels, width, height, Commons.Style.space(64), Commons.Style.spacing.sm, overview.windowFooterHeight);
    }

    Item {
        id: cardLayer
        anchors.fill: parent
        // The original style grows the whole arrangement out of the
        // top-left corner. A single transform does that without
        // resizing any card, so no layout, text elision, or layer
        // texture is redone per frame.
        scale: overview.animationStyle === "original" && overview.motionTarget > 0
            ? overview.motionProgress
            : 1
        transformOrigin: Item.TopLeft

        Repeater {
            model: screenWindow.cardToplevels

            delegate: WindowCard {
                controller: overview
                screenToplevels: screenWindow.screenToplevels
                acceptsKeyboard: screenWindow.acceptsKeyboard
                windowLayout: look.windowLayout
                layoutAreaWidth: look.width
                layoutAreaHeight: look.height
            }
        }
    }
}
