import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// A window's live capture filling this item, with rounded corners and a
// placeholder until a frame arrives. Size it to the window's aspect ratio.
// Children are drawn over the capture, inside the rounded corners.
Rectangle {
    id: thumbnail

    required property var toplevel
    property bool live: false
    default property alias overlay: overlayLayer.data

    color: Commons.Color.background
    clip: true
    layer.enabled: true

    Text {
        anchors.centerIn: parent
        text: "Live preview unavailable"
        textFormat: Text.PlainText
        color: Commons.Color.menu.text
        font.family: Commons.Style.font.menuFamily
        font.pixelSize: Commons.Style.font.body
        opacity: 0.45
    }

    // Captured at twice the size and scaled down, so text stays crisp.
    Item {
        anchors.centerIn: parent
        width: parent.width * 2
        height: parent.height * 2
        scale: 0.5
        layer.enabled: true
        layer.smooth: true

        ScreencopyView {
            anchors.fill: parent
            captureSource: WindowModel.waylandFor(thumbnail.toplevel)
            live: thumbnail.live
            paintCursor: false
        }
    }

    Item {
        id: overlayLayer
        anchors.fill: parent
        z: 2
    }

    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: thumbnail.radius
        color: "black"
        visible: false
        layer.enabled: true
        layer.smooth: true
    }
}
