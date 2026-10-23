import QtQuick
import "TimeLayout.js" as TimeLayout
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// The Time Machine look: windows recede down a tunnel by when they were last
// used, the most recent in front. Each open starts on the selection; from
// there the camera travels through time on a spring, stars drift past as it
// moves, and a ruler on the right marks every step back.
Look {
    id: look

    readonly property var toplevels: screenWindow.screenToplevels
    // One snapshot of the listed windows and each one's recency rank, 0 for the
    // most recently focused; cards and ticks read their slot here so slot and
    // rank never come from two different moments.
    readonly property var timeline: {
        var revision = overview.modelRevision;
        return {
            toplevels: look.toplevels,
            ranks: TimeLayout.ranks(look.toplevels.map(top => WindowModel.focusHistoryFor(top)))
        };
    }
    // The selection's rank and window from one read of the snapshot.
    readonly property var centre: {
        const snapshot = look.timeline;
        const slot = snapshot.toplevels.indexOf(look.overview.selection);
        return { rank: slot >= 0 ? snapshot.ranks[slot] : 0, window: slot >= 0 ? snapshot.toplevels[slot] : null };
    }
    readonly property int selectedRank: centre.rank
    readonly property var centreWindow: centre.window
    readonly property int starCount: 72
    readonly property real starSpan: 8

    // The animated camera, as a (fractional) rank; it trails selectedRank on a spring.
    property real position: selectedRank
    property bool springing: true
    // Edge bump: the camera lurches past the end of time and back.
    property real bump: 0
    property real wheelTravel: 0

    Behavior on position {
        enabled: look.springing
        SpringAnimation {
            spring: look.overview.juiceSpring ? 2.2 : 3.2
            damping: look.overview.juiceSpring ? 0.2 : 0.55
            epsilon: 0.001
        }
    }

    windowLayout: TimeLayout.navRects(timeline.ranks)

    // Each open puts the camera on the selection at once; the spring is only
    // for travel within a session.
    function snapHome() {
        look.springing = false;
        look.position = Qt.binding(() => look.selectedRank);
        look.springing = true;
    }

    Component.onCompleted: look.snapHome()
    Connections {
        target: look.overview
        function onOpenedChanged() {
            if (look.overview.opened)
                look.snapHome();
        }
        function onEdgeBumped(dx, dy) {
            lurch.lean = (dy !== 0 ? -dy : dx) * 0.35;
            lurch.restart();
        }
    }

    SequentialAnimation {
        id: lurch
        property real lean: 0
        NumberAnimation { target: look; property: "bump"; to: lurch.lean; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: look; property: "bump"; to: 0; duration: 420; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.35 }
    }

    WheelHandler {
        enabled: !look.overview.settingsOpen && !look.overview.previewToplevel
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (event) {
            look.wheelTravel += event.angleDelta.y;
            // One step per notch; scrolling up goes back in time.
            while (Math.abs(look.wheelTravel) >= 120) {
                const notch = look.wheelTravel > 0 ? 120 : -120;
                look.wheelTravel -= notch;
                look.overview.moveDirectional(0, notch > 0 ? -1 : 1, look.windowLayout, false);
            }
        }
    }

    // A glow where the tunnel vanishes.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: look.height * 0.6
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.alpha(Commons.Color.accent, 0.16) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    // The star field drifts toward the viewer as the camera travels back.
    Item {
        anchors.fill: parent
        opacity: look.overview.previewToplevel ? 0.3 : 1

        Repeater {
            model: look.starCount

            Rectangle {
                required property int index
                readonly property var star: TimeLayout.star(index, look.position * 1.5, look.starSpan, look.width, look.height)
                x: star.x - width / 2
                y: star.y - height / 2
                width: star.size
                height: star.size
                radius: width / 2
                color: index % 5 === 0 ? Commons.Color.accent : Commons.Color.foreground
                opacity: star.opacity * 0.8
            }
        }
    }

    // Cards stack by depth among themselves, above the backdrop.
    Item {
        anchors.fill: parent

        Repeater {
            model: look.screenWindow.cardToplevels

            delegate: TimeCard {
                stack: look
            }
        }
    }

    // The timeline: one tick per window, now at the bottom, older above.
    Item {
        id: ruler
        anchors.right: parent.right
        anchors.rightMargin: Commons.Style.space(36)
        anchors.verticalCenter: parent.verticalCenter
        width: Commons.Style.space(220)
        height: look.height * 0.7
        visible: look.toplevels.length > 1 && !look.overview.previewToplevel
        readonly property real step: Math.min(Commons.Style.space(32), height / Math.max(1, look.toplevels.length - 1))

        Rectangle {
            anchors.right: parent.right
            y: ruler.height - (look.toplevels.length - 1) * ruler.step
            width: Commons.Style.space(1)
            height: (look.toplevels.length - 1) * ruler.step
            color: Qt.alpha(Commons.Color.accent, 0.35)
        }

        Repeater {
            model: look.timeline.toplevels

            Item {
                id: tick
                required property var modelData
                required property int index
                readonly property int rank: look.timeline.ranks[index]
                readonly property bool current: tick.modelData === look.overview.selection
                anchors.right: parent.right
                y: ruler.height - rank * ruler.step - height / 2
                width: ruler.width
                height: Math.max(ruler.step, Commons.Style.space(8))

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Commons.Style.space(tick.current ? 28 : (tick.rank % 5 === 0 ? 16 : 9))
                    height: Commons.Style.space(tick.current ? 3 : 1)
                    color: tick.current ? Commons.Color.accent : Qt.alpha(Commons.Color.foreground, 0.5)
                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Commons.Style.space(40)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: tick.current || tick.rank === 0
                    text: (tick.rank === 0 ? "now" : tick.rank + " back") + (tick.current ? " · " + WindowModel.appNameFor(tick.modelData) : "")
                    textFormat: Text.PlainText
                    color: tick.current ? Commons.Color.accent : Commons.Color.menu.text
                    opacity: tick.current ? 1 : 0.6
                    font.family: Commons.Style.font.menuFamily
                    font.pixelSize: Commons.Style.font.bodySmall
                    font.bold: tick.current
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: look.screenWindow.acceptsKeyboard
                    cursorShape: Qt.PointingHandCursor
                    onClicked: look.overview.selectedToplevel = tick.modelData
                }
            }
        }
    }

    LookCaption {
        anchors.horizontalCenter: parent.horizontalCenter
        y: look.height * 0.9
        width: Math.min(look.width - Commons.Style.space(96), Commons.Style.space(1100))
        overview: look.overview
        toplevel: look.overview.previewToplevel ? null : look.centreWindow
        detail: look.centreWindow
            ? (WindowModel.appIdFor(look.centreWindow) || "Application") + "   ·   Workspace "
                + look.overview.workspaceName(look.centreWindow) + "   ·   "
                + (look.selectedRank === 0 ? "most recent" : look.selectedRank + (look.selectedRank === 1 ? " step back" : " steps back"))
            : ""
        opacity: Math.max(0, 1 - Math.abs(look.position - look.selectedRank) * 2)
    }
}
