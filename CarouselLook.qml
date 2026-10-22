import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "CarouselLayout.js" as CarouselLayout
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// The carousel look: every window on one arc, the selection large and front
// and centre, its neighbours turned away in perspective. The arc follows the
// selection on a spring, and opening the overview spins it into place.
Look {
    id: look

    readonly property var toplevels: screenWindow.screenToplevels
    readonly property int selectedIndex: toplevels.indexOf(overview.selection)
    readonly property int centreIndex: Math.max(0, selectedIndex)
    readonly property var centreWindow: toplevels[centreIndex] || null
    // The animated centre; it trails centreIndex on a spring.
    property real position: centreIndex
    property bool springing: true
    property real wheelTravel: 0

    Behavior on position {
        enabled: look.springing
        SpringAnimation {
            spring: look.overview.juiceSpring ? 2.4 : 3.2
            damping: look.overview.juiceSpring ? 0.16 : 0.55
            epsilon: 0.001
        }
    }

    // Edge bump: the arc leans toward the missing window and snaps back.
    property real bump: 0
    Connections {
        target: look.overview
        function onEdgeBumped(dx, dy) {
            if (dx === 0)
                return;
            rubberBand.lean = dx * 0.35;
            rubberBand.restart();
        }
    }
    SequentialAnimation {
        id: rubberBand
        property real lean: 0
        NumberAnimation { target: look; property: "bump"; to: rubberBand.lean; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: look; property: "bump"; to: 0; duration: 420; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.35 }
    }

    // How far the arc lags its target; springy motion stretches cards along travel by it.
    readonly property real stretch: overview.juiceSpring ? Math.min(0.12, Math.abs(position - centreIndex) * 0.1) : 0

    windowLayout: {
        var revision = overview.modelRevision;
        return CarouselLayout.layout(toplevels.map(top => overview.aspectRatioFor(top)), selectedIndex, width, height);
    }

    // Each open starts the arc a little to the right and lets it spin home.
    function spinIn() {
        look.springing = false;
        look.position = look.centreIndex + Math.min(3, Math.max(1, look.toplevels.length - 1 - look.centreIndex));
        look.springing = true;
        look.position = Qt.binding(() => look.centreIndex);
    }

    Component.onCompleted: look.spinIn()
    Connections {
        target: look.overview
        function onOpenedChanged() {
            if (look.overview.opened)
                look.spinIn();
        }
    }

    WheelHandler {
        enabled: !look.overview.settingsOpen && !look.overview.previewToplevel
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (event) {
            look.wheelTravel += event.angleDelta.y || -event.angleDelta.x;
            // One window per notch; scrolling up or left moves left.
            while (Math.abs(look.wheelTravel) >= 120) {
                const notch = look.wheelTravel > 0 ? 120 : -120;
                look.wheelTravel -= notch;
                look.overview.moveDirectional(notch > 0 ? -1 : 1, 0, look.windowLayout, false);
            }
        }
    }

    // A soft pool of light on the floor under the front card.
    Rectangle {
        readonly property var front: CarouselLayout.place(0, 16 / 9, look.width, look.height)
        x: look.width / 2 - width / 2
        y: front.y + front.height - height * 0.35
        width: look.width * 0.55
        height: look.height * 0.16
        radius: height / 2
        color: Commons.Color.accent
        opacity: look.toplevels.length ? 0.16 : 0
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 64
            autoPaddingEnabled: true
        }
    }

    Repeater {
        model: screenWindow.cardToplevels

        delegate: CarouselCard {
            controller: look.overview
            screenToplevels: look.toplevels
            acceptsKeyboard: look.screenWindow.acceptsKeyboard
            position: look.position + look.bump
            stretch: look.stretch
            areaWidth: look.width
            areaHeight: look.height
        }
    }

    // The front window's name, under the arc.
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: look.height * 0.84
        width: Math.min(look.width - Commons.Style.space(96), Commons.Style.space(1100))
        spacing: Commons.Style.spacing.sm
        visible: look.centreWindow !== null && !look.overview.previewToplevel
        opacity: Math.max(0, 1 - Math.abs(look.position - look.centreIndex) * 2)

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            spacing: Commons.Style.spacing.lg

            Image {
                Layout.preferredWidth: Commons.Style.space(36)
                Layout.preferredHeight: Commons.Style.space(36)
                source: look.centreWindow ? look.overview.iconFor(look.centreWindow) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Text {
                Layout.maximumWidth: parent.parent.width - Commons.Style.space(60)
                text: look.centreWindow ? String(look.centreWindow.title || WindowModel.appIdFor(look.centreWindow) || "Untitled window") : ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Commons.Color.menu.text
                font.family: Commons.Style.font.menuFamily
                font.pixelSize: Commons.Style.font.displayLarge
                font.bold: true
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: look.centreWindow
                ? (WindowModel.appIdFor(look.centreWindow) || "Application") + "   ·   Workspace "
                    + look.overview.workspaceName(look.centreWindow) + "   ·   " + (look.centreIndex + 1) + " / " + look.toplevels.length
                : ""
            textFormat: Text.PlainText
            color: Commons.Color.menu.text
            opacity: 0.6
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.font.heading
        }
    }
}
