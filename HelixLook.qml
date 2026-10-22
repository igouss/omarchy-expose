import QtQuick
import "HelixLayout.js" as HelixLayout
import "WorkspacePlanes.js" as WorkspacePlanes
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// The helix look: Strata's floors wound around a glowing spine like a spiral
// staircase, each window at its real place on its floor. The tower turns on a
// spring to bring the selection's floor to the front.
Look {
    id: look

    readonly property var toplevels: screenWindow.screenToplevels
    readonly property var screenViewport: ({ x: 0, y: 0, width: screenWindow.width, height: screenWindow.height })

    // One snapshot of the listed windows with their planes; cards read their slot
    // here so slot and plane never come from two different moments.
    readonly property var strata: {
        var revision = overview.modelRevision;
        return WorkspacePlanes.snapshot(look.toplevels, look.screenViewport);
    }

    // The selection's slot and plane from one read of the snapshot.
    readonly property var centre: {
        const snapshot = look.strata;
        const slot = snapshot.toplevels.indexOf(look.overview.selection);
        return { plane: slot >= 0 ? snapshot.planeOf[slot] : 0, window: slot >= 0 ? snapshot.toplevels[slot] : null };
    }
    readonly property int centrePlane: centre.plane
    readonly property var centreWindow: centre.window
    readonly property real reach: HelixLayout.reach
    readonly property real planeMaxWidth: width * 0.42
    readonly property real planeMaxHeight: height * 0.34

    // The animated camera, as a (fractional) plane index; it trails centrePlane on a spring.
    property real position: centrePlane
    property bool springing: true
    // Edge bump: the camera leans toward a missing plane; the selection shakes sideways.
    property real bump: 0
    property real bumpX: 0
    property real wheelTravel: 0

    Behavior on position {
        enabled: look.springing
        SpringAnimation {
            spring: look.overview.juiceSpring ? 2.4 : 3.2
            damping: look.overview.juiceSpring ? 0.18 : 0.55
            epsilon: 0.001
        }
    }

    windowLayout: strata.nav

    // A plane's size, where it sits, and how it is laid back, for planes and cards alike.
    function planeGeometry(planeIndex) {
        var plane = look.strata.planes[planeIndex];
        var size = WorkspacePlanes.fitPlane(plane ? plane.extent : look.screenViewport, look.planeMaxWidth, look.planeMaxHeight);
        var placed = HelixLayout.placeFloor(planeIndex - look.position - look.bump, look.width, look.height, look.planeMaxHeight);
        return {
            x: placed.centreX - size.width / 2,
            y: placed.centreY - size.height / 2,
            width: size.width,
            height: size.height,
            placed: placed
        };
    }

    // Each open starts the camera a plane below and lets it settle.
    function riseIn() {
        look.springing = false;
        look.position = look.centrePlane + (look.centrePlane + 1 < look.strata.planes.length ? 1 : -0.6);
        look.springing = true;
        look.position = Qt.binding(() => look.centrePlane);
    }

    Component.onCompleted: look.riseIn()
    Connections {
        target: look.overview
        function onOpenedChanged() {
            if (look.overview.opened)
                look.riseIn();
        }
        function onEdgeBumped(dx, dy) {
            if (dy !== 0) {
                cameraLean.lean = dy * 0.3;
                cameraLean.restart();
            } else {
                sideShake.lean = dx * Commons.Style.space(16);
                sideShake.restart();
            }
        }
    }

    SequentialAnimation {
        id: cameraLean
        property real lean: 0
        NumberAnimation { target: look; property: "bump"; to: cameraLean.lean; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: look; property: "bump"; to: 0; duration: 420; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.35 }
    }

    SequentialAnimation {
        id: sideShake
        property real lean: 0
        NumberAnimation { target: look; property: "bumpX"; to: sideShake.lean; duration: 60; easing.type: Easing.OutQuad }
        NumberAnimation { target: look; property: "bumpX"; to: 0; duration: 320; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.3 }
    }

    WheelHandler {
        enabled: !look.overview.settingsOpen && !look.overview.previewToplevel
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (event) {
            look.wheelTravel += event.angleDelta.y;
            // One step per notch; scrolling up moves up.
            while (Math.abs(look.wheelTravel) >= 120) {
                const notch = look.wheelTravel > 0 ? 120 : -120;
                look.wheelTravel -= notch;
                look.overview.moveDirectional(0, notch > 0 ? -1 : 1, look.windowLayout, false);
            }
        }
    }

    Repeater {
        model: look.strata.planes

        delegate: Item {
            id: plane
            required property var modelData
            required property int index
            readonly property var geometry: look.planeGeometry(index)
            readonly property var placed: geometry.placed
            readonly property bool front: index === look.centrePlane

            x: geometry.x
            y: geometry.y
            width: geometry.width
            height: geometry.height
            z: placed.z * 10
            visible: placed.opacity > 0
            opacity: look.overview.previewToplevel ? 0.25 : placed.opacity
            transform: [
                Scale { origin.x: plane.width / 2; origin.y: plane.height / 2; xScale: plane.placed.scale; yScale: plane.placed.scale },
                Rotation { origin.x: plane.width / 2; origin.y: plane.height / 2; axis { x: 1; y: 0; z: 0 } angle: plane.placed.angle },
                Rotation { origin.x: plane.width / 2; origin.y: plane.height / 2; axis { x: 0; y: 1; z: 0 } angle: plane.placed.turn }
            ]

            // The glass.
            Rectangle {
                anchors.fill: parent
                anchors.margins: -Commons.Style.space(18)
                radius: Commons.Style.space(14)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.alpha(Commons.Color.accent, plane.front ? 0.2 : 0.1) }
                    GradientStop { position: 1; color: Qt.alpha(Commons.Color.background, 0.55) }
                }
                border.color: Qt.alpha(Commons.Color.accent, plane.front ? 0.75 : 0.3)
                border.width: Commons.Style.space(plane.front ? 2 : 1)
            }

            // Faint survey lines across the glass.
            Repeater {
                model: 11
                Rectangle {
                    required property int index
                    x: (index + 1) * plane.width / 12
                    width: 1
                    height: plane.height
                    color: Qt.alpha(Commons.Color.accent, 0.08)
                }
            }

            // The monitor's viewport, where the workspace is on screen.
            Rectangle {
                readonly property var rect: WorkspacePlanes.onPlane(plane.modelData.viewport, plane.modelData.extent, plane)
                x: rect.x
                y: rect.y
                width: rect.width
                height: rect.height
                visible: plane.modelData.extent.width > plane.modelData.viewport.width + 1
                color: "transparent"
                radius: Commons.Style.space(6)
                border.color: Qt.alpha(Commons.Color.accent, 0.45)
                border.width: Commons.Style.space(1)
            }

            // The workspace's name, painted on the glass beside it.
            Text {
                anchors.right: parent.left
                anchors.rightMargin: Commons.Style.space(40)
                anchors.verticalCenter: parent.verticalCenter
                text: look.overview.formatWorkspaceLabel(plane.modelData.name)
                textFormat: Text.PlainText
                color: Commons.Color.accent
                opacity: plane.front ? 0.95 : 0.45
                font.family: Commons.Style.font.menuFamily
                font.pixelSize: Commons.Style.space(96)
                font.bold: true
            }

            // Back planes darken.
            Rectangle {
                anchors.fill: parent
                anchors.margins: -Commons.Style.space(18)
                radius: Commons.Style.space(14)
                color: "black"
                opacity: plane.placed.shade
            }
        }
    }

    // The spine the floors turn around, between the floors in front and those behind.
    Rectangle {
        x: look.width / 2 - width / 2
        y: 0
        width: Commons.Style.space(6)
        height: look.height
        z: HelixLayout.spineZ(look.width) * 10 + 5
        radius: width / 2
        opacity: look.overview.previewToplevel ? 0.2 : 0.85
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.4; color: Commons.Color.accent }
            GradientStop { position: 0.75; color: Qt.alpha(Commons.Color.accent, 0.4) }
            GradientStop { position: 1; color: "transparent" }
        }
    }

    Repeater {
        model: screenWindow.cardToplevels

        delegate: PlaneCard {
            stack: look
        }
    }

    // Floors below fade under the caption.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: look.height * 0.26
        z: 3000
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.55; color: Qt.alpha(Commons.Color.background, 0.82) }
            GradientStop { position: 1; color: Qt.alpha(Commons.Color.background, 0.92) }
        }
    }

    LookCaption {
        anchors.horizontalCenter: parent.horizontalCenter
        z: 3001
        y: look.height * 0.88
        width: Math.min(look.width - Commons.Style.space(96), Commons.Style.space(1100))
        overview: look.overview
        toplevel: look.overview.previewToplevel ? null : look.centreWindow
        detail: look.centreWindow
            ? (WindowModel.appIdFor(look.centreWindow) || "Application") + "   ·   Workspace "
                + look.overview.workspaceName(look.centreWindow) + "   ·   step " + (look.centrePlane + 1) + " / " + look.strata.planes.length
            : ""
        opacity: Math.max(0, 1 - Math.abs(look.position - look.centrePlane) * 2)
    }
}
