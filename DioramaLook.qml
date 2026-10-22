import QtQuick
import "DioramaLayout.js" as DioramaLayout
import "WorkspacePlanes.js" as WorkspacePlanes
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// The diorama look: the desktop as a small model. Every workspace is a slab
// with visible thickness, laid out in a grid on the floor; windows stand on
// their slab at their real places as blocks with their live preview on top.
// The selection's block rises and its slab lights up.
Look {
    id: look

    readonly property var toplevels: screenWindow.screenToplevels
    readonly property var screenViewport: ({ x: 0, y: 0, width: screenWindow.width, height: screenWindow.height })

    // One snapshot of the listed windows with their workspaces, each slab's floor
    // rect, and each window's; slabs and blocks read it so slot, slab, and floor
    // never come from two different moments.
    readonly property var strata: {
        var revision = overview.modelRevision;
        var snapshot = WorkspacePlanes.snapshot(look.toplevels, look.screenViewport);
        var places = DioramaLayout.arrange(snapshot.planes.map(plane => plane.extent));
        snapshot.slabs = snapshot.planes.map((plane, index) =>
            ({ index: index, plane: plane, floor: DioramaLayout.onFloor(plane.extent, plane.extent, places[index]) }));
        snapshot.floors = snapshot.frames.map((frame, index) =>
            DioramaLayout.onFloor(frame, snapshot.planes[snapshot.planeOf[index]].extent, places[snapshot.planeOf[index]]));
        return snapshot;
    }

    // The whole model, slabs' undersides to the tallest block, fitted above the caption.
    readonly property var view: {
        var points = [];
        look.strata.slabs.forEach(function (slab) {
            points = points.concat(DioramaLayout.corners(slab.floor, -DioramaLayout.slabThickness),
                DioramaLayout.corners(slab.floor, DioramaLayout.blockHeight + DioramaLayout.liftHeight));
        });
        var fitted = DioramaLayout.fit(DioramaLayout.bounds(points), look.width * 0.9, look.height * 0.8);
        return { scale: fitted.scale, x: fitted.x + look.width * 0.05, y: fitted.y + look.height * 0.02 };
    }

    // The selection's slab and window from one read of the snapshot.
    readonly property var centre: {
        const snapshot = look.strata;
        const slot = snapshot.toplevels.indexOf(look.overview.selection);
        return { plane: slot >= 0 ? snapshot.planeOf[slot] : -1, window: slot >= 0 ? snapshot.toplevels[slot] : null };
    }
    readonly property int centrePlane: centre.plane
    readonly property var centreWindow: centre.window

    // 0 to 1 as the model builds on open: slabs settle and blocks grow.
    property real build: 1
    // Edge bump: the selection's block hops.
    property real hop: 0

    // The four corners of a floor rect at height h, on screen.
    function cornersOnScreen(floor, h) {
        return DioramaLayout.corners(floor, h).map(point => DioramaLayout.toScreen(point, look.view));
    }

    // How far the slab is above its place while the model builds; its blocks ride with it.
    function dropFor(planeIndex) {
        return (1 - look.build) * -look.height * 0.06 * (planeIndex + 1);
    }

    function depthOrder(floor) {
        return DioramaLayout.depthOf(floor) * look.view.scale;
    }

    // Arrows move by where the lids sit on screen.
    windowLayout: strata.floors.map(function (floor) {
        var box = DioramaLayout.bounds(look.cornersOnScreen(floor, DioramaLayout.blockHeight));
        return { x: box.x, y: box.y, width: box.width, height: box.height };
    })

    function buildIn() {
        buildUp.restart();
    }

    Component.onCompleted: look.buildIn()
    Connections {
        target: look.overview
        function onOpenedChanged() {
            if (look.overview.opened)
                look.buildIn();
        }
        function onEdgeBumped(dx, dy) {
            hopUp.restart();
        }
    }

    NumberAnimation {
        id: buildUp
        target: look
        property: "build"
        from: 0
        to: 1
        duration: 520
        easing.type: look.overview.juiceSpring ? Easing.OutBack : Easing.OutCubic
        easing.overshoot: 2.2
    }

    SequentialAnimation {
        id: hopUp
        NumberAnimation { target: look; property: "hop"; to: 90; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: look; property: "hop"; to: 0; duration: 480; easing.type: Easing.OutBounce }
    }

    // The slabs, back to front.
    Repeater {
        model: look.strata.slabs

        delegate: Item {
            id: slab
            required property var modelData
            readonly property var floor: modelData.floor
            readonly property bool lit: modelData.index === look.centrePlane
            readonly property var topCorners: look.cornersOnScreen(floor, 0)
            readonly property var bottomCorners: look.cornersOnScreen(floor, -DioramaLayout.slabThickness)

            anchors.fill: parent
            z: look.depthOrder(floor) - 1e6
            opacity: look.overview.previewToplevel ? 0.3 : 1
            transform: Translate { y: look.dropFor(slab.modelData.index) }

            // A soft flat shadow on the ground below the slab.
            DioramaFace {
                p0: ({ x: slab.bottomCorners[0].x + 18, y: slab.bottomCorners[0].y + 26 })
                px: ({ x: slab.bottomCorners[1].x + 18, y: slab.bottomCorners[1].y + 26 })
                py: ({ x: slab.bottomCorners[2].x + 18, y: slab.bottomCorners[2].y + 26 })
                color: "black"
                opacity: 0.28
                radius: Commons.Style.space(10)
            }

            // The two edges that face the viewer.
            DioramaFace {
                p0: slab.topCorners[2]
                px: slab.topCorners[3]
                py: slab.bottomCorners[2]
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.tint(Commons.Color.background, Qt.alpha(Commons.Color.accent, slab.lit ? 0.45 : 0.22)) }
                    GradientStop { position: 1; color: Qt.darker(Commons.Color.background, 1.4) }
                }
            }
            DioramaFace {
                p0: slab.topCorners[1]
                px: slab.topCorners[3]
                py: slab.bottomCorners[1]
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.tint(Commons.Color.background, Qt.alpha(Commons.Color.accent, slab.lit ? 0.3 : 0.14)) }
                    GradientStop { position: 1; color: Qt.darker(Commons.Color.background, 1.8) }
                }
            }

            // The top: tinted glass with survey lines and the monitor's outline.
            DioramaFace {
                id: topFace
                p0: slab.topCorners[0]
                px: slab.topCorners[1]
                py: slab.topCorners[2]
                color: Qt.tint(Commons.Color.background, Qt.alpha(Commons.Color.accent, slab.lit ? 0.18 : 0.08))
                border.color: Qt.alpha(Commons.Color.accent, slab.lit ? 0.9 : 0.35)
                border.width: Commons.Style.space(slab.lit ? 2 : 1)

                Repeater {
                    model: 9
                    Rectangle {
                        required property int index
                        x: (index + 1) * topFace.width / 10
                        width: 1
                        height: topFace.height
                        color: Qt.alpha(Commons.Color.accent, 0.1)
                    }
                }

                Rectangle {
                    readonly property var rect: WorkspacePlanes.onPlane(slab.modelData.plane.viewport, slab.modelData.plane.extent, topFace)
                    x: rect.x
                    y: rect.y
                    width: rect.width
                    height: rect.height
                    visible: slab.modelData.plane.extent.width > slab.modelData.plane.viewport.width + 1
                    color: "transparent"
                    border.color: Qt.alpha(Commons.Color.accent, 0.5)
                    border.width: 1
                    radius: Commons.Style.space(4)
                }
            }
        }
    }

    // Blocks stack by depth among themselves, above every slab.
    Item {
        anchors.fill: parent

        Repeater {
            model: look.screenWindow.cardToplevels

            delegate: DioramaBlock {
                stack: look
            }
        }
    }

    // Each slab's name, a sign beside its left edge, above every block.
    Repeater {
        model: look.strata.slabs

        delegate: Text {
            id: sign
            required property var modelData
            readonly property var edge: look.cornersOnScreen(modelData.floor, 0)
            x: (edge[0].x + edge[2].x) / 2 - width - Commons.Style.space(28)
            y: (edge[0].y + edge[2].y) / 2 - height / 2 + look.dropFor(modelData.index)
            text: look.overview.formatWorkspaceLabel(modelData.plane.name)
            textFormat: Text.PlainText
            color: Commons.Color.accent
            visible: !look.overview.previewToplevel
            opacity: modelData.index === look.centrePlane ? 0.95 : 0.45
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.space(72)
            font.bold: true
        }
    }

    LookCaption {
        anchors.horizontalCenter: parent.horizontalCenter
        y: look.height * 0.86
        width: Math.min(look.width - Commons.Style.space(96), Commons.Style.space(1100))
        overview: look.overview
        toplevel: look.overview.previewToplevel ? null : look.centreWindow
        detail: look.centreWindow
            ? (WindowModel.appIdFor(look.centreWindow) || "Application") + "   ·   Workspace "
                + look.overview.workspaceName(look.centreWindow) + "   ·   slab " + (look.centrePlane + 1) + " / " + look.strata.planes.length
            : ""
    }
}
