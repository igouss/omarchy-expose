import QtQuick
import QtQuick.Effects
import "AtlasLayout.js" as AtlasLayout
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// One window on the map at its real place, drawn wherever the camera puts it.
// A click selects it; a click on the selection opens it. Hover selects
// nothing, because it would fly the camera under the pointer.
Item {
    id: card

    required property var modelData
    required property var stack
    readonly property var controller: stack.overview

    // Slot and map rect from one read of the snapshot.
    readonly property var spot: {
        const atlas = card.stack.atlas;
        const slot = atlas.toplevels.indexOf(card.modelData);
        return { slot: slot, rect: slot >= 0 ? atlas.rects[slot] : { x: 0, y: 0, width: 1, height: 1 } };
    }
    readonly property bool inLayout: spot.slot >= 0
    readonly property var placed: AtlasLayout.toScreen(spot.rect, stack.camera, stack.width, stack.height)
    readonly property bool shown: AtlasLayout.onScreen(placed, stack.width, stack.height)
    readonly property bool selected: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.selection
    readonly property bool previewed: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.previewToplevel
    readonly property bool focusedWindow: modelData === controller.originToplevel
    readonly property var previewRect: controller.previewRectFor(modelData,
        Qt.rect(placed.x, placed.y, placed.width, placed.height), stack.width, stack.height, 0, 0)

    // 0 on the map, 1 in Quick Look.
    property real lookBlend: previewed ? 1 : 0
    Behavior on lookBlend {
        enabled: card.controller.motionSettled
        NumberAnimation { duration: card.controller.previewAnimationDuration; easing.type: card.controller.previewAnimationEasing }
    }

    function blend(from, to) { return from + (to - from) * card.lookBlend; }

    visible: inLayout && (shown || previewed)
    x: blend(placed.x + (previewed ? 0 : stack.bumpX), previewRect.x)
    y: blend(placed.y + (previewed ? 0 : stack.bumpY), previewRect.y)
    width: blend(placed.width, previewRect.width)
    height: blend(placed.height, previewRect.height)
    z: previewed ? 1000 : (selected ? 2 : 1)
    opacity: controller.previewToplevel && !previewed ? 0.2 : 1

    transform: [
        Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: 1 + punch.zoom * 0.1
            yScale: xScale
        },
        Rotation {
            origin.x: card.width / 2
            origin.y: card.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: tilt.aroundY
        },
        Rotation {
            origin.x: card.width / 2
            origin.y: card.height / 2
            axis { x: 1; y: 0; z: 0 }
            angle: tilt.aroundX
        }
    ]

    // The selection's glow, under the thumbnail.
    Loader {
        anchors.fill: parent
        anchors.margins: -Commons.Style.space(6)
        active: card.selected && !card.previewed
        sourceComponent: Rectangle {
            radius: Commons.Style.space(10)
            color: Commons.Color.accent
            opacity: 0.75 * card.controller.selectionBreath
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 40
                autoPaddingEnabled: true
            }
        }
    }

    WindowThumbnail {
        id: thumbnail
        anchors.fill: parent
        radius: Commons.Style.space(6)
        toplevel: card.modelData
        live: card.controller.opened && card.inLayout && card.shown

        Rectangle {
            anchors.fill: parent
            color: "white"
            opacity: punch.flash
        }
    }

    Rectangle {
        anchors.fill: thumbnail
        radius: thumbnail.radius
        color: "transparent"
        border.color: card.selected ? Commons.Color.accent : Qt.alpha(Commons.Color.accent, 0.3)
        border.width: Commons.Style.space(card.selected ? 2 : 1)
    }

    // The application's name, like a label on the map, while there is room for it.
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Commons.Style.space(8)
        width: tag.implicitWidth + Commons.Style.space(14)
        height: tag.implicitHeight + Commons.Style.space(6)
        radius: height / 2
        visible: !card.previewed && card.width > Commons.Style.space(150)
        color: card.selected ? Commons.Color.accent : Qt.alpha(Commons.Color.background, 0.8)

        Text {
            id: tag
            anchors.centerIn: parent
            text: WindowModel.appNameFor(card.modelData)
            textFormat: Text.PlainText
            color: card.selected ? Commons.Color.background : Commons.Color.foreground
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.font.caption
            font.bold: card.selected
        }
    }

    // The window the overview was opened from.
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Commons.Style.space(8)
        width: Commons.Style.space(12)
        height: width
        radius: width / 2
        visible: card.focusedWindow
        color: Commons.Color.accent
        border.color: Commons.Color.background
        border.width: Commons.Style.space(2)
    }

    JuicePunch {
        id: punch
        anchors.fill: parent
        controller: card.controller
        toplevel: card.modelData
    }

    PointerTilt {
        id: tilt
        area: pointer
        active: card.controller.juiceTilt && card.selected && !card.previewed
    }

    CardPointer {
        id: pointer
        controller: card.controller
        toplevel: card.modelData
        acceptsKeyboard: card.stack.screenWindow.acceptsKeyboard
        selected: card.selected
        previewed: card.previewed
    }
}
