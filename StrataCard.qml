import QtQuick
import QtQuick.Effects
import "StrataLayout.js" as StrataLayout
import qs.Commons as Commons

// One window lying on its workspace's plane at its real place. It shares the
// plane's transform (origin at the plane's centre), so it lies flat on the
// glass. A click selects it; a click on the selection opens it. Hover selects
// nothing, because it would move the camera under the pointer.
Item {
    id: card

    required property var modelData
    required property var stack
    readonly property var controller: stack.overview

    readonly property int slot: stack.strata.toplevels.indexOf(modelData)
    readonly property bool inLayout: slot >= 0
    readonly property int planeIndex: inLayout ? stack.strata.planeOf[slot] : 0
    readonly property var plane: stack.planeGeometry(planeIndex)
    readonly property var placed: plane.placed
    readonly property var spot: inLayout
        ? StrataLayout.onPlane(stack.strata.frames[slot], stack.strata.planes[planeIndex].extent, plane)
        : { x: 0, y: 0, width: 1, height: 1 }
    readonly property bool selected: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.selection
    readonly property bool previewed: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.previewToplevel
    readonly property bool focusedWindow: modelData === controller.originToplevel
    readonly property bool nearby: Math.abs(planeIndex - stack.position) <= StrataLayout.reach + 0.5
    readonly property var previewRect: controller.previewRectFor(modelData,
        Qt.rect(plane.x + spot.x, plane.y + spot.y, spot.width, spot.height), stack.width, stack.height, 0, 0)

    // 0 on its plane, 1 in Quick Look.
    property real lookBlend: previewed ? 1 : 0
    Behavior on lookBlend {
        enabled: card.controller.motionSettled
        NumberAnimation { duration: card.controller.previewAnimationDuration; easing.type: card.controller.previewAnimationEasing }
    }

    function blend(from, to) { return from + (to - from) * card.lookBlend; }

    visible: inLayout && placed.opacity > 0
    x: blend(plane.x + spot.x, previewRect.x) + (selected ? stack.bumpX : 0)
    y: blend(plane.y + spot.y, previewRect.y)
    width: blend(spot.width, previewRect.width)
    height: blend(spot.height, previewRect.height)
    z: previewed ? 5000 : placed.z * 10 + (selected ? 3 : 1)
    opacity: controller.previewToplevel && !previewed ? 0.2 : placed.opacity

    // The plane's centre, in this card's coordinates.
    readonly property real planeOriginX: blend(plane.width / 2 - spot.x, width / 2)
    readonly property real planeOriginY: blend(plane.height / 2 - spot.y, height / 2)
    property real lift: (selected && !previewed ? 1.06 : 1) * (1 + punch.zoom * 0.1)

    transform: [
        Scale {
            origin.x: card.planeOriginX
            origin.y: card.planeOriginY
            xScale: card.blend(card.placed.scale, 1)
            yScale: xScale
        },
        Rotation {
            origin.x: card.planeOriginX
            origin.y: card.planeOriginY
            axis { x: 1; y: 0; z: 0 }
            angle: card.blend(card.placed.angle, 0) + tilt.aroundX
        },
        Rotation {
            origin.x: card.width / 2
            origin.y: card.height / 2
            axis { x: 0; y: 1; z: 0 }
            angle: tilt.aroundY
        },
        Scale {
            origin.x: card.width / 2
            origin.y: card.height / 2
            xScale: card.lift
            yScale: card.lift
        }
    ]

    Behavior on lift {
        enabled: card.controller.motionSettled
        NumberAnimation {
            duration: card.controller.juiceSpring ? 320 : card.controller.previewFadeDuration
            easing.type: card.controller.juiceSpring ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 3
        }
    }

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
        live: card.controller.opened && card.inLayout && card.nearby

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
        border.color: card.selected ? Commons.Color.accent : Qt.alpha(Commons.Color.accent, 0.25)
        border.width: Commons.Style.space(card.selected ? 2 : 1)
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

    // Only the selection leans toward the pointer; the rest lie on the glass.
    PointerTilt {
        id: tilt
        area: pointer
        active: card.controller.juiceTilt && card.selected && !card.previewed
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: card.controller.juiceTilt
        enabled: !card.controller.settingsOpen && (!card.controller.previewToplevel || card.previewed)
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.MiddleButton)
                card.controller.requestClose(card.modelData);
            else if (card.selected)
                card.controller.activate(card.modelData);
            else if (card.stack.screenWindow.acceptsKeyboard)
                card.controller.selectedToplevel = card.modelData;
        }
    }
}
