import QtQuick
import QtQuick.Effects
import "CarouselLayout.js" as CarouselLayout
import qs.Commons as Commons

// One window on the carousel: its live thumbnail turned to its place on the
// arc, with a floor reflection. A click on a side card brings it to the
// front; a click on the front card opens it. Hover selects nothing, because
// it would spin the carousel under the pointer.
Item {
    id: card

    required property var modelData
    required property var controller
    required property var screenToplevels
    required property bool acceptsKeyboard
    // The carousel's animated centre, as a (fractional) index into screenToplevels.
    required property real position
    // Horizontal stretch while the arc travels; height gives up half of it.
    required property real stretch
    required property real areaWidth
    required property real areaHeight

    readonly property int slot: card.screenToplevels.indexOf(modelData)
    readonly property bool inLayout: slot >= 0
    readonly property real offset: slot - card.position
    readonly property real aspectRatio: card.controller.aspectRatioFor(modelData)
    readonly property var placed: CarouselLayout.place(offset, aspectRatio, card.areaWidth, card.areaHeight)
    readonly property bool front: card.acceptsKeyboard && inLayout && modelData === card.controller.selection
    readonly property bool previewed: card.acceptsKeyboard && inLayout && modelData === card.controller.previewToplevel
    readonly property bool focusedWindow: modelData === card.controller.originToplevel
    readonly property bool nearby: Math.abs(offset) <= CarouselLayout.reach + 0.5
    readonly property var previewRect: card.controller.previewRectFor(modelData,
        Qt.rect(placed.x, placed.y, placed.width, placed.height), card.areaWidth, card.areaHeight, 0, 0)
    // 0 on the arc, 1 in Quick Look; the spring moves the arc, this blends out of it.
    property real lookBlend: previewed ? 1 : 0
    Behavior on lookBlend {
        enabled: card.controller.motionSettled
        NumberAnimation { duration: card.controller.previewAnimationDuration; easing.type: card.controller.previewAnimationEasing }
    }

    function blend(from, to) { return from + (to - from) * card.lookBlend; }

    visible: inLayout && placed.opacity > 0
    x: blend(placed.x, previewRect.x)
    y: blend(placed.y, previewRect.y)
    width: blend(placed.width, previewRect.width)
    height: blend(placed.height, previewRect.height)
    z: previewed ? 1000 : placed.z
    opacity: card.controller.previewToplevel && !previewed ? 0.2 : placed.opacity

    transform: [
        Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: card.blend(card.placed.scale, 1) * (1 + card.stretch) * (1 + punch.zoom * 0.1)
            yScale: card.blend(card.placed.scale, 1) * (1 - card.stretch / 2) * (1 + punch.zoom * 0.1)
        },
        Rotation {
            origin.x: card.width / 2
            origin.y: card.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: card.blend(card.placed.angle, 0)
        }
    ]

    // The selection's glow, drawn behind the thumbnail.
    Loader {
        anchors.fill: parent
        anchors.margins: -Commons.Style.space(6)
        active: card.front && !card.previewed
        sourceComponent: Rectangle {
            radius: thumbnail.radius + Commons.Style.space(6)
            color: Commons.Color.accent
            opacity: 0.7
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
        live: card.controller.opened && card.inLayout && card.nearby

        // Side cards darken as they turn away.
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
        border.color: Commons.Color.accent
        border.width: Commons.Style.space(2)
        visible: card.front
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

    // The floor reflection: the bottom of the thumbnail mirrored and faded out.
    Item {
        id: reflection
        anchors.top: parent.bottom
        anchors.topMargin: Commons.Style.space(6)
        width: parent.width
        height: parent.height * 0.2
        visible: !card.previewed && card.nearby
        opacity: 0.25
        layer.enabled: visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: reflectionFade
            maskThresholdMin: 0
            maskSpreadAtMin: 1
        }

        ShaderEffectSource {
            anchors.fill: parent
            sourceItem: thumbnail
            sourceRect: Qt.rect(0, thumbnail.height - reflection.height, thumbnail.width, reflection.height)
            live: card.controller.opened
            transform: Scale { origin.y: reflection.height / 2; yScale: -1 }
        }
    }

    Rectangle {
        id: reflectionFade
        anchors.fill: reflection
        visible: false
        layer.enabled: true
        gradient: Gradient {
            GradientStop { position: 0; color: "white" }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    JuicePunch {
        id: punch
        anchors.fill: parent
        controller: card.controller
        toplevel: card.modelData
    }

    MouseArea {
        anchors.fill: parent
        enabled: !card.controller.settingsOpen && (!card.controller.previewToplevel || card.previewed)
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.MiddleButton)
                card.controller.requestClose(card.modelData);
            else if (card.front)
                card.controller.activate(card.modelData);
            else if (card.acceptsKeyboard)
                card.controller.selectedToplevel = card.modelData;
        }
    }
}
