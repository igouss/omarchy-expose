import QtQuick
import QtQuick.Layouts
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// One window on the glass HUD: a frosted glass pane holding its live
// thumbnail, its title in large type, and a readout line, framed by corner
// brackets. Its rect comes from the look's grid packing: padding, thumbnail,
// padding, title band, padding. Hover selects, as on the grid; a click opens.
Item {
    id: card

    required property var modelData
    required property var stack
    required property real areaWidth
    required property real areaHeight
    readonly property var controller: stack.overview

    readonly property int slot: stack.toplevels.indexOf(modelData)
    readonly property bool inLayout: slot >= 0
    readonly property bool selected: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.selection
    readonly property bool previewed: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.previewToplevel
    readonly property bool exitingPreview: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.previewExitToplevel
    readonly property bool focusedWindow: modelData === controller.originToplevel
    readonly property real padding: stack.cardPadding

    // An excluded card keeps its last rect, so it neither shrinks to the
    // origin nor flies back in from it.
    readonly property var packedRectSource: inLayout ? stack.windowLayout[slot] || null : null
    property var packedRect: Qt.rect(0, 0, 1, 1)
    onPackedRectSourceChanged: {
        if (packedRectSource)
            packedRect = packedRectSource;
    }
    Component.onCompleted: {
        if (packedRectSource)
            packedRect = packedRectSource;
    }
    readonly property var previewRect: controller.previewRectFor(modelData, packedRect, areaWidth, areaHeight, padding, stack.titleBandHeight)
    readonly property var layoutRect: previewed ? previewRect : packedRect

    // Each open powers the panes up one after another.
    property real boot: 1
    Connections {
        target: card.controller
        function onOpenedChanged() {
            if (card.controller.opened)
                bootUp.restart();
        }
    }
    SequentialAnimation {
        id: bootUp
        PropertyAction { target: card; property: "boot"; value: 0 }
        PauseAnimation { duration: Math.max(0, Math.min(card.slot, 12)) * 28 }
        NumberAnimation { target: card; property: "boot"; to: 1; duration: 260; easing.type: Easing.OutCubic }
    }

    visible: inLayout
    x: layoutRect.x
    y: layoutRect.y + (1 - boot) * Commons.Style.space(24)
    width: layoutRect.width
    height: layoutRect.height
    z: previewed ? 11 : (exitingPreview ? 10 : (selected ? 1 : 0))
    scale: 1 + punch.zoom * 0.1
    opacity: boot * (controller.previewToplevel ? (previewed ? 1 : 0.2) : (selected ? 1 : 0.78))
    transform: [
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

    // The frosted pane: the background tinted most of the way to opaque, under
    // a wash of the text colour that is brighter at the top. No backdrop blur.
    Rectangle {
        anchors.fill: parent
        radius: card.stack.cardRadius
        color: Qt.alpha(Commons.Color.background, 0.72)
    }

    Rectangle {
        anchors.fill: parent
        radius: card.stack.cardRadius
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Commons.Color.menu.text, card.selected ? 0.16 : 0.1) }
            GradientStop { position: 1; color: Qt.alpha(Commons.Color.menu.text, 0.03) }
        }
        border.color: Qt.alpha(Commons.Color.menu.text, card.selected ? 0.32 : 0.14)
        border.width: 1
    }

    // The pane's top edge catching the light.
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - card.stack.cardRadius * 2
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(Commons.Color.menu.text, 0.55) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Corner { anchors.left: parent.left; anchors.top: parent.top }
    Corner { anchors.right: parent.right; anchors.top: parent.top; rotation: 90 }
    Corner { anchors.right: parent.right; anchors.bottom: parent.bottom; rotation: 180 }
    Corner { anchors.left: parent.left; anchors.bottom: parent.bottom; rotation: 270 }

    Item {
        id: thumbnailBox
        x: card.padding
        y: card.padding
        width: card.width - card.padding * 2
        height: card.height - card.stack.titleBandHeight - card.padding * 3

        WindowThumbnail {
            readonly property real ratio: card.controller.aspectRatioFor(card.modelData)
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height * ratio)
            height: Math.min(parent.height, parent.width / ratio)
            radius: Math.max(0, card.stack.cardRadius - card.padding / 2)
            toplevel: card.modelData
            live: card.controller.opened && card.inLayout

            Rectangle {
                anchors.fill: parent
                color: "white"
                opacity: punch.flash
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
        }
    }

    ColumnLayout {
        x: card.padding
        y: card.height - card.padding - card.stack.titleBandHeight
        width: card.width - card.padding * 2
        height: card.stack.titleBandHeight
        spacing: Commons.Style.space(2)

        Text {
            Layout.fillWidth: true
            text: String(card.modelData.title || WindowModel.appIdFor(card.modelData) || "Untitled window")
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: Commons.Color.menu.text
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.font.displayLarge
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            text: (WindowModel.appIdFor(card.modelData) || "application").toUpperCase()
                + "   ▸   WS " + card.controller.workspaceName(card.modelData)
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: card.selected ? Commons.Color.accent : Commons.Color.menu.text
            opacity: card.selected ? 1 : 0.6
            font.family: Commons.Style.font.family
            font.pixelSize: Commons.Style.font.caption
            font.letterSpacing: Commons.Style.space(2)
        }
    }

    JuicePunch {
        id: punch
        anchors.fill: parent
        z: 20
        controller: card.controller
        toplevel: card.modelData
    }

    PointerTilt {
        id: tilt
        area: pointer
        active: card.controller.juiceTilt && !card.previewed
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: !card.controller.settingsOpen && (!card.controller.previewToplevel || card.previewed)
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onEnabledChanged: {
            if (!enabled && card.controller.hoveredToplevel === card.modelData)
                card.controller.hoveredToplevel = null;
        }
        onEntered: {
            if (card.stack.screenWindow.acceptsKeyboard) {
                card.controller.hoveredToplevel = card.modelData;
                card.controller.selectedToplevel = card.modelData;
            }
        }
        onExited: {
            if (card.stack.screenWindow.acceptsKeyboard && card.controller.hoveredToplevel === card.modelData)
                card.controller.hoveredToplevel = null;
        }
        onClicked: function (mouse) {
            if (mouse.button === Qt.MiddleButton)
                card.controller.requestClose(card.modelData);
            else
                card.controller.activate(card.modelData);
        }
    }

    Behavior on x { enabled: card.controller.motionSettled; CardMotion {} }
    Behavior on y { enabled: card.controller.motionSettled && card.boot === 1; CardMotion {} }
    Behavior on width { enabled: card.controller.motionSettled; CardMotion {} }
    Behavior on height { enabled: card.controller.motionSettled; CardMotion {} }

    component CardMotion: NumberAnimation {
        duration: card.controller.previewAnimationDuration
        easing.type: card.controller.previewAnimationEasing
    }

    // An L-shaped bracket; rotate it for each corner.
    component Corner: Item {
        width: Commons.Style.space(18)
        height: width
        transformOrigin: Item.Center
        opacity: card.selected ? 0.95 : 0.4

        Rectangle { width: parent.width; height: Commons.Style.space(2); color: Commons.Color.accent }
        Rectangle { width: Commons.Style.space(2); height: parent.height; color: Commons.Color.accent }
    }
}
