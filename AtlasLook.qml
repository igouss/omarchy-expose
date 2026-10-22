import QtQuick
import "AtlasLayout.js" as AtlasLayout
import "WorkspacePlanes.js" as WorkspacePlanes
import "WindowModel.js" as WindowModel
import qs.Commons as Commons

// The atlas look: the whole desktop as one map. Workspaces lie side by side as
// regions, every window at its real place, including a scrolling layout's
// off-screen windows. The camera centres the selection with the map around it
// and flies there on a spring; the wheel zooms out to everything.
Look {
    id: look

    readonly property var toplevels: screenWindow.screenToplevels
    readonly property var screenViewport: ({ x: 0, y: 0, width: screenWindow.width, height: screenWindow.height })

    // One snapshot of the listed windows, each workspace's region and viewport
    // on the map, and each window's map rect; regions and cards read it so slot
    // and rect never come from two different moments.
    readonly property var atlas: {
        var revision = overview.modelRevision;
        var snapshot = WorkspacePlanes.snapshot(look.toplevels, look.screenViewport);
        var places = AtlasLayout.arrange(snapshot.planes.map(plane => plane.extent));
        snapshot.regions = snapshot.planes.map((plane, index) => ({
            index: index,
            plane: plane,
            rect: AtlasLayout.onMap(plane.extent, plane.extent, places[index]),
            viewport: AtlasLayout.onMap(plane.viewport, plane.extent, places[index])
        }));
        snapshot.rects = snapshot.frames.map((frame, index) =>
            AtlasLayout.onMap(frame, snapshot.planes[snapshot.planeOf[index]].extent, places[snapshot.planeOf[index]]));
        snapshot.bounds = AtlasLayout.union(snapshot.regions.map(region => region.rect)) || { x: 0, y: 0, width: look.width, height: look.height };
        return snapshot;
    }

    // The selection's slot, region, and window from one read of the snapshot.
    readonly property var centre: {
        const snapshot = look.atlas;
        const slot = snapshot.toplevels.indexOf(look.overview.selection);
        return { slot: slot, region: slot >= 0 ? snapshot.planeOf[slot] : -1, window: slot >= 0 ? snapshot.toplevels[slot] : null };
    }
    readonly property var centreWindow: centre.window
    readonly property int centreRegion: centre.region

    // The map fills the area above the caption.
    readonly property real mapHeight: height * 0.8
    property bool zoomedOut: false

    // Close enough to read a window, far enough to keep the map around it.
    readonly property real closestZoom: 0.32

    // A camera that frames `rect` in the map area, its centre raised above the caption.
    function cameraFor(rect, maxZoom) {
        var camera = AtlasLayout.frame(rect, look.width, look.mapHeight, maxZoom);
        return { x: camera.x, y: camera.y + (look.height - look.mapHeight) / 2 / camera.zoom, zoom: camera.zoom };
    }

    readonly property var overviewCamera: cameraFor(atlas.bounds)
    // The selection with the map around it, or everything when zoomed out.
    readonly property var targetCamera: {
        var atlas = look.atlas;
        var slot = atlas.toplevels.indexOf(look.overview.selection);
        if (look.zoomedOut || slot < 0)
            return look.overviewCamera;
        return look.cameraFor(atlas.rects[slot], look.closestZoom);
    }

    // The animated camera; each part trails targetCamera on a spring.
    property real cameraX: targetCamera.x
    property real cameraY: targetCamera.y
    property real cameraZoom: targetCamera.zoom
    property bool springing: true
    readonly property var camera: ({ x: cameraX, y: cameraY, zoom: cameraZoom })
    // Edge bump: the map leans toward the missing window, in screen pixels.
    property real bumpX: 0
    property real bumpY: 0
    property real wheelTravel: 0

    Behavior on cameraX {
        enabled: look.springing
        SpringAnimation { spring: look.overview.juiceSpring ? 2.6 : 3.4; damping: look.overview.juiceSpring ? 0.24 : 0.6; epsilon: 0.5 }
    }
    Behavior on cameraY {
        enabled: look.springing
        SpringAnimation { spring: look.overview.juiceSpring ? 2.6 : 3.4; damping: look.overview.juiceSpring ? 0.24 : 0.6; epsilon: 0.5 }
    }
    Behavior on cameraZoom {
        enabled: look.springing
        SpringAnimation { spring: look.overview.juiceSpring ? 2.6 : 3.4; damping: look.overview.juiceSpring ? 0.24 : 0.6; epsilon: 0.0001 }
    }

    windowLayout: atlas.rects

    // Each open starts over everything and flies in to the selection.
    function flyIn() {
        look.zoomedOut = false;
        look.springing = false;
        look.cameraX = look.overviewCamera.x;
        look.cameraY = look.overviewCamera.y;
        look.cameraZoom = look.overviewCamera.zoom;
        look.springing = true;
        look.cameraX = Qt.binding(() => look.targetCamera.x);
        look.cameraY = Qt.binding(() => look.targetCamera.y);
        look.cameraZoom = Qt.binding(() => look.targetCamera.zoom);
    }

    Component.onCompleted: look.flyIn()
    Connections {
        target: look.overview
        function onOpenedChanged() {
            if (look.overview.opened)
                look.flyIn();
        }
        function onEdgeBumped(dx, dy) {
            lean.toX = dx * Commons.Style.space(28);
            lean.toY = dy * Commons.Style.space(28);
            lean.restart();
        }
    }

    ParallelAnimation {
        id: lean
        property real toX: 0
        property real toY: 0
        SequentialAnimation {
            NumberAnimation { target: look; property: "bumpX"; to: lean.toX; duration: 80; easing.type: Easing.OutQuad }
            NumberAnimation { target: look; property: "bumpX"; to: 0; duration: 420; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.35 }
        }
        SequentialAnimation {
            NumberAnimation { target: look; property: "bumpY"; to: lean.toY; duration: 80; easing.type: Easing.OutQuad }
            NumberAnimation { target: look; property: "bumpY"; to: 0; duration: 420; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.35 }
        }
    }

    // Scrolling down zooms out to the whole map, up zooms back in to the selection.
    WheelHandler {
        enabled: !look.overview.settingsOpen && !look.overview.previewToplevel
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (event) {
            look.wheelTravel += event.angleDelta.y;
            if (Math.abs(look.wheelTravel) >= 120) {
                look.zoomedOut = look.wheelTravel < 0;
                look.wheelTravel = 0;
            }
        }
    }

    // The sheet the map is printed on, so the desktop behind does not show through.
    Rectangle {
        anchors.fill: parent
        radius: Commons.Style.space(18)
        color: Qt.alpha(Commons.Color.background, 0.72)
        border.color: Qt.alpha(Commons.Color.accent, 0.2)
        border.width: Commons.Style.space(1)
    }

    // The graticule: map lines a nice distance apart, labelled along the top.
    Item {
        id: graticule
        anchors.fill: parent
        readonly property var lines: AtlasLayout.gridLines(look.camera, look.width, look.height, Commons.Style.space(90))
        opacity: look.overview.previewToplevel ? 0.3 : 1

        Repeater {
            model: 48
            Rectangle {
                required property int index
                readonly property real at: graticule.lines.xs[index] ?? -1
                visible: index < graticule.lines.xs.length
                x: at + look.bumpX
                width: 1
                height: look.height
                color: Qt.alpha(Commons.Color.accent, 0.07)

                Text {
                    x: Commons.Style.space(4)
                    y: Commons.Style.space(4)
                    text: Math.round((parent.at - look.width / 2) / look.cameraZoom + look.cameraX)
                    textFormat: Text.PlainText
                    color: Commons.Color.accent
                    opacity: 0.35
                    font.family: Commons.Style.font.family
                    font.pixelSize: Commons.Style.font.caption
                }
            }
        }

        Repeater {
            model: 32
            Rectangle {
                required property int index
                visible: index < graticule.lines.ys.length
                y: (graticule.lines.ys[index] ?? -1) + look.bumpY
                width: look.width
                height: 1
                color: Qt.alpha(Commons.Color.accent, 0.07)
            }
        }
    }

    // Workspace regions, named like places, with the monitor's viewport outlined.
    Repeater {
        model: look.atlas.regions

        delegate: Item {
            id: region
            required property var modelData
            readonly property var placed: AtlasLayout.toScreen(modelData.rect, look.camera, look.width, look.height)
            readonly property var viewport: AtlasLayout.toScreen(modelData.viewport, look.camera, look.width, look.height)
            readonly property bool current: modelData.index === look.centreRegion
            readonly property real pad: Commons.Style.space(14)

            opacity: look.overview.previewToplevel ? 0.3 : 1

            Rectangle {
                x: region.placed.x - region.pad + look.bumpX
                y: region.placed.y - region.pad + look.bumpY
                width: region.placed.width + 2 * region.pad
                height: region.placed.height + 2 * region.pad
                radius: Commons.Style.space(16)
                color: Qt.alpha(Commons.Color.accent, region.current ? 0.08 : 0.04)
                border.color: Qt.alpha(Commons.Color.accent, region.current ? 0.6 : 0.25)
                border.width: Commons.Style.space(1)
            }

            Rectangle {
                x: region.viewport.x + look.bumpX
                y: region.viewport.y + look.bumpY
                width: region.viewport.width
                height: region.viewport.height
                visible: region.modelData.rect.width > region.modelData.viewport.width + 1
                color: "transparent"
                radius: Commons.Style.space(8)
                border.color: Qt.alpha(Commons.Color.accent, 0.5)
                border.width: Commons.Style.space(1)
            }

            Text {
                readonly property real size: Math.max(Commons.Style.font.bodySmall, Math.min(Commons.Style.space(40), region.placed.height * 0.08))
                x: region.placed.x - region.pad + look.bumpX
                y: region.placed.y - region.pad - height - Commons.Style.space(6) + look.bumpY
                text: ("Workspace " + look.overview.formatWorkspaceLabel(region.modelData.plane.name)).toUpperCase()
                textFormat: Text.PlainText
                color: Commons.Color.accent
                opacity: region.current ? 0.95 : 0.55
                font.family: Commons.Style.font.menuFamily
                font.pixelSize: size
                font.bold: true
                font.letterSpacing: size * 0.3
            }
        }
    }

    Repeater {
        model: look.screenWindow.cardToplevels

        delegate: AtlasCard {
            stack: look
        }
    }

    // The scale bar, bottom left.
    Item {
        id: scaleBar
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Commons.Style.space(36)
        readonly property real step: AtlasLayout.niceStep(Commons.Style.space(140) / look.cameraZoom)
        width: step * look.cameraZoom
        height: Commons.Style.space(30)
        visible: !look.overview.previewToplevel

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Commons.Style.space(3)
            color: Commons.Color.accent
        }
        Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; width: Commons.Style.space(2); height: Commons.Style.space(12); color: Commons.Color.accent }
        Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; width: Commons.Style.space(2); height: Commons.Style.space(12); color: Commons.Color.accent }

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            text: scaleBar.step + " px"
            textFormat: Text.PlainText
            color: Commons.Color.accent
            font.family: Commons.Style.font.family
            font.pixelSize: Commons.Style.font.caption
        }
    }

    // The minimap, bottom right: every region and window, and the camera's view.
    Rectangle {
        id: minimap
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Commons.Style.space(36)
        width: Commons.Style.space(300)
        height: Commons.Style.space(150)
        radius: Commons.Style.space(10)
        color: Qt.alpha(Commons.Color.background, 0.75)
        border.color: Qt.alpha(Commons.Color.accent, 0.4)
        border.width: Commons.Style.space(1)
        visible: !look.overview.previewToplevel && look.atlas.regions.length > 0
        clip: true
        readonly property var view: AtlasLayout.frame(look.atlas.bounds, width, height)

        function place(rect) {
            return AtlasLayout.toScreen(rect, minimap.view, minimap.width, minimap.height);
        }

        Repeater {
            model: look.atlas.regions
            Rectangle {
                required property var modelData
                readonly property var at: minimap.place(modelData.rect)
                x: at.x; y: at.y; width: at.width; height: at.height
                color: Qt.alpha(Commons.Color.accent, 0.08)
                border.color: Qt.alpha(Commons.Color.accent, 0.3)
                border.width: 1
            }
        }

        Repeater {
            model: look.atlas.rects
            Rectangle {
                required property var modelData
                required property int index
                readonly property var at: minimap.place(modelData)
                x: at.x; y: at.y; width: at.width; height: at.height
                color: index === look.centre.slot ? Commons.Color.accent : Qt.alpha(Commons.Color.foreground, 0.3)
            }
        }

        // The part of the map on screen now.
        Rectangle {
            readonly property var at: minimap.place({
                x: look.cameraX - look.width / 2 / look.cameraZoom,
                y: look.cameraY - look.height / 2 / look.cameraZoom,
                width: look.width / look.cameraZoom,
                height: look.height / look.cameraZoom
            })
            x: at.x; y: at.y; width: at.width; height: at.height
            color: "transparent"
            border.color: Commons.Color.accent
            border.width: Commons.Style.space(2)
            radius: Commons.Style.space(3)
        }
    }

    LookCaption {
        anchors.horizontalCenter: parent.horizontalCenter
        y: look.height * 0.86
        width: Math.min(look.width - Commons.Style.space(96) - 2 * minimap.width, Commons.Style.space(1100))
        overview: look.overview
        toplevel: look.overview.previewToplevel ? null : look.centreWindow
        detail: look.centreWindow
            ? (WindowModel.appIdFor(look.centreWindow) || "Application") + "   ·   Workspace "
                + look.overview.workspaceName(look.centreWindow) + (look.zoomedOut ? "   ·   scroll up to zoom in" : "")
            : ""
    }
}
