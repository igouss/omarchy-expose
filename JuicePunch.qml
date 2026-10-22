import QtQuick
import QtQuick.Particles
import qs.Commons as Commons

// Activation punch for one card: when the controller reports this card's
// window is being activated, `zoom` and `flash` run once and sparks are
// thrown from the card's edge. Cards scale by (1 + zoom * 0.1) and overlay
// white at `flash` opacity.
Item {
    id: punch

    required property var controller
    required property var toplevel
    property real zoom: 0
    property real flash: 0

    Connections {
        target: punch.controller
        function onActivating(top) {
            if (top !== punch.toplevel)
                return;
            strike.restart();
            sparksAlive.restart();
        }
    }

    ParallelAnimation {
        id: strike
        NumberAnimation { target: punch; property: "zoom"; from: 0; to: 1; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2 }
        SequentialAnimation {
            NumberAnimation { target: punch; property: "flash"; from: 0; to: 0.65; duration: 40 }
            NumberAnimation { target: punch; property: "flash"; to: 0; duration: 220; easing.type: Easing.OutQuad }
        }
    }

    // Long enough for every spark to die out.
    Timer { id: sparksAlive; interval: 1000 }

    Loader {
        anchors.fill: parent
        active: sparksAlive.running
        sourceComponent: Item {
            ParticleSystem { id: sparks }

            ImageParticle {
                system: sparks
                source: "qrc:///particleresources/glowdot.png"
                color: Commons.Color.accent
                colorVariation: 0.15
                entryEffect: ImageParticle.Scale
            }

            Emitter {
                id: emitter
                system: sparks
                anchors.fill: parent
                enabled: false
                lifeSpan: 700
                lifeSpanVariation: 250
                size: Commons.Style.space(26)
                sizeVariation: Commons.Style.space(8)
                endSize: Commons.Style.space(2)
                shape: EllipseShape { fill: false }
                velocity: AngleDirection {
                    angleVariation: 360
                    magnitude: Commons.Style.space(320)
                    magnitudeVariation: Commons.Style.space(180)
                }
            }

            Component.onCompleted: emitter.burst(90)
        }
    }
}
