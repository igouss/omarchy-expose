import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons as Commons

// The glass HUD's selection mark: a ring whose gradient sweeps around it,
// over a glow. It travels to `target` (a rect, or null) on a spring once the
// overview is open, so it slides between cards instead of jumping.
Item {
    id: ring

    required property var overview
    required property var target
    required property bool shown
    property string label: ""
    property real radius: 0
    readonly property real margin: Commons.Style.space(8)
    readonly property real strokeWidth: Commons.Style.space(3)
    property real sweep: 0

    // Settles on the first frame after opening, so the ring starts on the selection.
    property bool armed: false
    Timer {
        interval: 50
        running: ring.overview.opened
        onTriggered: ring.armed = true
    }
    Connections {
        target: ring.overview
        function onOpenedChanged() {
            if (!ring.overview.opened)
                ring.armed = false;
        }
        function onEdgeBumped(dx, dy) {
            if (!ring.shown)
                return;
            bumpShake.dx = dx;
            bumpShake.dy = dy;
            bumpShake.restart();
        }
    }

    // The last target, kept while there is none so the ring fades out in place.
    property rect frame: Qt.rect(0, 0, 0, 0)
    function follow() {
        if (ring.target)
            ring.frame = Qt.rect(ring.target.x - ring.margin, ring.target.y - ring.margin, ring.target.width + ring.margin * 2, ring.target.height + ring.margin * 2);
    }
    onTargetChanged: ring.follow()
    Component.onCompleted: ring.follow()

    x: frame.x
    y: frame.y
    width: frame.width
    height: frame.height
    z: 3
    opacity: shown ? 1 : 0
    visible: opacity > 0
    transform: Translate { id: bumpShift }

    Behavior on x { enabled: ring.armed; RingSpring {} }
    Behavior on y { enabled: ring.armed; RingSpring {} }
    Behavior on width { enabled: ring.armed; RingSpring {} }
    Behavior on height { enabled: ring.armed; RingSpring {} }
    Behavior on opacity { NumberAnimation { duration: ring.overview.previewFadeDuration } }

    NumberAnimation on sweep {
        from: 0
        to: 360
        duration: 2600
        loops: Animation.Infinite
        running: ring.overview.opened && ring.visible
    }

    // The glow: a wide copy of the comet alone, blurred, breathing with the selection pulse.
    GradientRing {
        anchors.fill: parent
        stroke: ring.strokeWidth * 4
        base: 0
        opacity: ring.overview.selectionBreath
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 48
            autoPaddingEnabled: true
        }
    }

    GradientRing {
        anchors.fill: parent
        stroke: ring.strokeWidth
    }

    // The selection's number, tagged on the ring's corner.
    Rectangle {
        x: ring.radius
        y: -height / 2
        width: tag.implicitWidth + Commons.Style.space(14)
        height: tag.implicitHeight + Commons.Style.space(4)
        radius: height / 2
        visible: ring.label !== ""
        color: Commons.Color.accent

        Text {
            id: tag
            anchors.centerIn: parent
            text: ring.label
            textFormat: Text.PlainText
            color: Commons.Color.background
            font.family: Commons.Style.font.family
            font.pixelSize: Commons.Style.font.caption
            font.bold: true
            font.letterSpacing: Commons.Style.space(1)
        }
    }

    SequentialAnimation {
        id: bumpShake
        property int dx: 0
        property int dy: 0
        readonly property real reach: Commons.Style.space(14)
        ParallelAnimation {
            NumberAnimation { target: bumpShift; property: "x"; to: bumpShake.dx * bumpShake.reach; duration: 60; easing.type: Easing.OutQuad }
            NumberAnimation { target: bumpShift; property: "y"; to: bumpShake.dy * bumpShake.reach; duration: 60; easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: bumpShift; property: "x"; to: 0; duration: 320; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.3 }
            NumberAnimation { target: bumpShift; property: "y"; to: 0; duration: 320; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.3 }
        }
    }

    // Springy motion lets the ring overshoot and settle.
    component RingSpring: SpringAnimation {
        spring: ring.overview.juiceSpring ? 3.2 : 4
        damping: ring.overview.juiceSpring ? 0.2 : 0.6
        epsilon: 0.25
    }

    component GradientRing: Shape {
        id: shape
        property real stroke: 1
        // How bright the ring is away from the comet.
        property real base: 0.3

        ShapePath {
            fillColor: "transparent"
            strokeWidth: shape.stroke
            strokeGradient: ConicalGradient {
                centerX: shape.width / 2
                centerY: shape.height / 2
                angle: ring.sweep
                // A dim ring with a comet: its tail brightens into a head at the seam.
                GradientStop { position: 0; color: Qt.alpha(Commons.Color.accent, shape.base) }
                GradientStop { position: 0.5; color: Qt.alpha(Commons.Color.accent, shape.base) }
                GradientStop { position: 0.9; color: Commons.Color.accent }
                GradientStop { position: 1; color: Commons.Color.menu.text }
            }

            PathRectangle {
                x: shape.stroke / 2
                y: shape.stroke / 2
                width: shape.width - shape.stroke
                height: shape.height - shape.stroke
                radius: Math.max(0, ring.radius - shape.stroke / 2)
            }
        }
    }
}
