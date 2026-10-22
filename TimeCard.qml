import QtQuick
import QtQuick.Effects
import "TimeLayout.js" as TimeLayout
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// One window in the Time Machine tunnel, at the depth of its recency rank,
// with a title tab that stays readable above the card in front. A click
// brings it to the front; a click on the front card opens it. Hover selects
// nothing, because it would fly the camera under the pointer.
Item {
    id: card

    required property var modelData
    required property var stack
    readonly property var controller: stack.overview

    readonly property int slot: stack.timeline.toplevels.indexOf(modelData)
    readonly property bool inLayout: slot >= 0
    readonly property real depth: inLayout ? stack.timeline.ranks[slot] - stack.position - stack.bump : 0
    readonly property var placed: TimeLayout.place(depth, controller.aspectRatioFor(modelData), stack.width, stack.height)
    readonly property bool selected: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.selection
    readonly property bool previewed: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.previewToplevel
    readonly property bool focusedWindow: modelData === controller.originToplevel
    readonly property bool nearby: depth > -0.6 && depth <= TimeLayout.reach + 0.5
    readonly property var previewRect: controller.previewRectFor(modelData,
        Qt.rect(placed.x, placed.y, placed.width, placed.height), stack.width, stack.height, 0, 0)

    // 0 in the tunnel, 1 in Quick Look.
    property real lookBlend: previewed ? 1 : 0
    Behavior on lookBlend {
        enabled: card.controller.motionSettled
        NumberAnimation { duration: card.controller.previewAnimationDuration; easing.type: card.controller.previewAnimationEasing }
    }

    function blend(from, to) { return from + (to - from) * card.lookBlend; }

    visible: inLayout && nearby && placed.opacity > 0
    x: blend(placed.x, previewRect.x)
    y: blend(placed.y, previewRect.y)
    width: blend(placed.width, previewRect.width)
    height: blend(placed.height, previewRect.height)
    z: previewed ? 100000 : placed.z
    opacity: controller.previewToplevel && !previewed ? 0.15 : placed.opacity

    transform: [
        Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: card.blend(card.placed.scale, 1) * (1 + punch.zoom * 0.1)
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

    // The title tab: the window's name on a strip above the card.
    Rectangle {
        id: tab
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.top
        anchors.bottomMargin: -radius
        height: Commons.Style.space(40) + radius
        radius: Commons.Style.space(10)
        visible: !card.previewed
        color: card.selected ? Commons.Color.accent : Qt.tint(Commons.Color.background, Qt.alpha(Commons.Color.foreground, 0.12))
        border.color: Qt.alpha(Commons.Color.accent, card.selected ? 1 : 0.35)
        border.width: Commons.Style.space(1)

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Commons.Style.space(16)
            anchors.rightMargin: Commons.Style.space(16)
            height: Commons.Style.space(40)
            verticalAlignment: Text.AlignVCenter
            text: WindowModel.appNameFor(card.modelData) + "  —  " + String(card.modelData.title || "untitled")
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: card.selected ? Commons.Color.background : Commons.Color.foreground
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.font.body
            font.bold: card.selected
        }

        // Older tabs darken with the card.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "black"
            opacity: card.placed.shade
        }
    }

    // The selection's glow, under the thumbnail.
    Loader {
        anchors.fill: parent
        anchors.topMargin: -Commons.Style.space(46)
        anchors.margins: -Commons.Style.space(6)
        active: card.selected && !card.previewed
        sourceComponent: Rectangle {
            radius: Commons.Style.space(16)
            color: Commons.Color.accent
            opacity: 0.6 * card.controller.selectionBreath
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 48
                autoPaddingEnabled: true
            }
        }
    }

    WindowThumbnail {
        id: thumbnail
        anchors.fill: parent
        radius: Commons.Style.space(10)
        toplevel: card.modelData
        live: card.controller.opened && card.inLayout && card.depth < 3

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: card.blend(card.placed.shade, 0)
        }

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

    // The window the overview was opened from.
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Commons.Style.space(10)
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
