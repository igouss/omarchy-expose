import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "CrtLayout.js" as CrtLayout
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// The CRT look: a terminal listing every window beside a phosphor monitor
// showing the selection, under a prompt that echoes the filter. Only the
// selection is captured live. Quick Look fills the screen with the monitor;
// opening a window powers the monitor off.
Look {
    id: look

    readonly property var toplevels: screenWindow.screenToplevels
    readonly property int selectedIndex: toplevels.indexOf(overview.selection)
    readonly property var monitorWindow: selectedIndex >= 0 ? toplevels[selectedIndex] : null
    // The phosphor: the theme's accent, so the tube matches the desktop.
    readonly property color phosphor: Commons.Color.accent
    readonly property real rowHeight: Commons.Style.space(34)
    readonly property real promptHeight: Commons.Style.space(48)
    readonly property var split: CrtLayout.panes(width, height - promptHeight, Commons.Style.space(32))
    readonly property real listWidth: split.list.width

    windowLayout: CrtLayout.rowRects(toplevels.length, rowHeight, listWidth)

    property real wheelTravel: 0

    // The list's scroll, kept so the selection stays in view.
    property real scroll: 0
    function follow() {
        look.scroll = CrtLayout.listOffset(look.selectedIndex, look.toplevels.length, look.rowHeight, listPane.height, look.scroll);
    }
    onSelectedIndexChanged: follow()
    onToplevelsChanged: follow()
    Behavior on scroll {
        SpringAnimation { spring: look.overview.juiceSpring ? 3 : 4; damping: look.overview.juiceSpring ? 0.3 : 0.7; epsilon: 0.25 }
    }

    // Each open types the list in.
    property real boot: 1
    function powerOn() {
        bootUp.restart();
        powerOff.stop();
        monitorPower.collapse = 0;
        monitorPower.squeeze = 0;
        look.scroll = CrtLayout.listOffset(look.selectedIndex, look.toplevels.length, look.rowHeight, listPane.height, 0);
    }
    Component.onCompleted: powerOn()
    NumberAnimation { id: bootUp; target: look; property: "boot"; from: 0; to: 1; duration: 520; easing.type: Easing.Linear }

    // 0 in its pane, 1 filling the look: Quick Look.
    property real lookBlend: overview.previewToplevel ? 1 : 0
    Behavior on lookBlend {
        enabled: look.overview.motionSettled
        NumberAnimation { duration: look.overview.previewAnimationDuration; easing.type: look.overview.previewAnimationEasing }
    }

    Connections {
        target: look.overview
        function onOpenedChanged() {
            if (look.overview.opened)
                look.powerOn();
        }
        function onEdgeBumped(dx, dy) {
            jitter.restart();
        }
        function onActivating(top) {
            if (top === look.monitorWindow)
                powerOff.restart();
        }
    }

    transform: Translate { id: shake }

    SequentialAnimation {
        id: jitter
        NumberAnimation { target: shake; property: "x"; to: Commons.Style.space(6); duration: 30 }
        NumberAnimation { target: shake; property: "x"; to: -Commons.Style.space(5); duration: 40 }
        NumberAnimation { target: shake; property: "x"; to: Commons.Style.space(3); duration: 40 }
        NumberAnimation { target: shake; property: "x"; to: 0; duration: 60; easing.type: Easing.OutQuad }
    }

    WheelHandler {
        enabled: !look.overview.settingsOpen && !look.overview.previewToplevel
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (event) {
            look.wheelTravel += event.angleDelta.y;
            // One line per notch; scrolling up moves up.
            while (Math.abs(look.wheelTravel) >= 120) {
                const notch = look.wheelTravel > 0 ? 120 : -120;
                look.wheelTravel -= notch;
                look.overview.moveDirectional(0, notch > 0 ? -1 : 1, look.windowLayout, false);
            }
        }
    }

    // The tube: everything sits on dark glass.
    Rectangle {
        anchors.fill: parent
        radius: Commons.Style.space(28)
        color: Qt.alpha(Commons.Color.background, 0.92)
        border.color: Qt.alpha(look.phosphor, 0.35)
        border.width: Commons.Style.space(2)
    }

    // The prompt, echoing the filter, with a cursor that breathes with the selection pulse.
    Row {
        id: prompt
        height: look.promptHeight
        spacing: 0

        x: Commons.Style.space(24)
        PromptText { text: "expose@omarchy:~$ grep -i " }
        PromptText { text: look.overview.filterText ? "\"" + look.overview.filterText + "\"" : ""; font.bold: true }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Commons.Style.space(12)
            height: Commons.Style.space(22)
            color: look.phosphor
            opacity: look.overview.selectionBreath
        }
    }

    PromptText {
        anchors.right: parent.right
        anchors.rightMargin: Commons.Style.space(24)
        y: 0
        height: look.promptHeight
        opacity: 0.6
        text: look.toplevels.length + " windows · " + (look.overview.workspaceScope === "current" ? "workspace " + look.screenWindow.screenWorkspaceLabel : "all workspaces")
    }

    Item {
        id: listPane
        x: look.split.list.x
        y: look.promptHeight + look.split.list.y
        width: look.split.list.width
        height: look.split.list.height
        onHeightChanged: look.follow()
        opacity: 1 - look.lookBlend

        // Clipped inside the glowing layer: the glow's padding would otherwise
        // show lines scrolled above the pane.
        Item {
            anchors.fill: parent
            clip: true

            // The cursor bar under the selected line.
            Rectangle {
                visible: look.selectedIndex >= 0 && look.screenWindow.acceptsKeyboard
                width: parent.width
                height: look.rowHeight
                y: cursorY - look.scroll
                color: look.phosphor
                opacity: 0.55 + 0.45 * look.overview.selectionBreath
                property real cursorY: Math.max(0, look.selectedIndex) * look.rowHeight
                Behavior on cursorY {
                    enabled: look.overview.motionSettled
                    SpringAnimation { spring: look.overview.juiceSpring ? 5 : 6; damping: look.overview.juiceSpring ? 0.25 : 0.8; epsilon: 0.25 }
                }
            }

            Item {
                y: -look.scroll
                width: parent.width
                height: look.toplevels.length * look.rowHeight

                Repeater {
                    model: look.screenWindow.cardToplevels
                    delegate: CrtRow { stack: look }
                }
            }
        }

        // Phosphor bloom on the text.
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: look.phosphor
            shadowBlur: 0.5
            shadowOpacity: 0.6
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            autoPaddingEnabled: true
        }
    }

    // The monitor: the selection's live picture in phosphor, behind scanlines
    // and a vignette. Quick Look grows it to the whole look.
    Item {
        id: monitor
        readonly property var pane: look.split.monitor
        x: pane.x * (1 - look.lookBlend)
        y: (look.promptHeight + pane.y) * (1 - look.lookBlend)
        width: pane.width + (look.width - pane.width) * look.lookBlend
        height: pane.height + (look.height - pane.height) * look.lookBlend
        z: 2
        visible: look.monitorWindow !== null

        Rectangle {
            anchors.fill: parent
            radius: Commons.Style.space(18)
            color: Qt.alpha(Commons.Color.background, 0.9)
            border.color: Qt.alpha(look.phosphor, 0.6)
            border.width: Commons.Style.space(2)
        }

        Text {
            id: tube
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Commons.Style.space(14)
            text: look.monitorWindow
                ? "/dev/tty" + (look.selectedIndex + 1) + " — " + CrtLayout.appName(WindowModel.appIdFor(look.monitorWindow))
                    + " — ws " + look.overview.workspaceName(look.monitorWindow)
                : ""
            textFormat: Text.PlainText
            elide: Text.ElideRight
            color: look.phosphor
            font.family: Commons.Style.font.family
            font.pixelSize: Commons.Style.font.body
            font.letterSpacing: Commons.Style.space(1)
        }

        Item {
            id: screenArea
            anchors.top: tube.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Commons.Style.space(14)

            // The power: collapse squeezes the picture to a line, squeeze then to a dot.
            Item {
                id: monitorPower
                property real collapse: 0
                property real squeeze: 0
                anchors.fill: parent
                transform: Scale {
                    origin.x: monitorPower.width / 2
                    origin.y: monitorPower.height / 2
                    xScale: 1 - 0.98 * monitorPower.squeeze
                    yScale: 1 - 0.99 * monitorPower.collapse
                }

                Item {
                    id: picture
                    readonly property real ratio: look.monitorWindow ? look.overview.aspectRatioFor(look.monitorWindow) : 16 / 9
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height * ratio)
                    height: Math.min(parent.height, parent.width / ratio)
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: look.phosphor
                        saturation: -1
                        brightness: 0.1
                        contrast: 0.35
                    }

                    WindowThumbnail {
                        anchors.fill: parent
                        radius: Commons.Style.space(10)
                        toplevel: look.monitorWindow
                        live: look.overview.opened
                    }
                }


                Rectangle {
                    anchors.fill: picture
                    color: "white"
                    opacity: Math.max(monitorPower.collapse, monitorPower.squeeze) * 0.8
                }
            }
        }

        SequentialAnimation {
            id: powerOff
            NumberAnimation { target: monitorPower; property: "collapse"; to: 1; duration: 90; easing.type: Easing.InQuad }
            NumberAnimation { target: monitorPower; property: "squeeze"; to: 1; duration: 80; easing.type: Easing.InQuad }
        }
    }

    // Scanlines over the whole tube, and its edges falling into shadow.
    Image {
        anchors.fill: parent
        z: 3
        source: Qt.resolvedUrl("assets/scanline.png")
        fillMode: Image.Tile
        smooth: false
    }

    Shape {
        anchors.fill: parent
        z: 3
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: look.width / 2
                centerY: look.height / 2
                centerRadius: Math.max(look.width, look.height) * 0.62
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0.6; color: "transparent" }
                GradientStop { position: 1; color: Qt.alpha("black", 0.55) }
            }
            PathRectangle { width: look.width; height: look.height; radius: Commons.Style.space(28) }
        }
    }

    component PromptText: Text {
        height: look.promptHeight
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.PlainText
        color: look.phosphor
        font.family: Commons.Style.font.family
        font.pixelSize: Commons.Style.font.heading
    }
}
