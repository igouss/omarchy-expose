import QtQuick
import QtTest
import "../WorkspacePlanes.js" as WorkspacePlanes
import "../GridLayout.js" as GridLayout

TestCase {
    name: "WorkspacePlanes"

    readonly property var viewport: ({ x: 0, y: 0, width: 2560, height: 1440 })
    readonly property var monitor: ({ x: 0, y: 0, width: 2560, height: 1440, scale: 1, lastIpcObject: { transform: 0 } })

    function windowOn(workspace, at, size) {
        return { title: "w", lastIpcObject: { at: at, size: size }, workspace: workspace, monitor: monitor };
    }

    function test_noWindowsNoPlanes() {
        let none = WorkspacePlanes.snapshot([], viewport);
        compare(none.planes.length, 0);
        compare(none.nav, []);
    }

    function test_oneWindowOnePlane() {
        let one = WorkspacePlanes.snapshot([windowOn({ id: 2, name: "2" }, [10, 20], [800, 600])], viewport);
        compare(one.planes.length, 1);
        compare(one.planes[0].name, "2");
        compare(one.planeOf, [0]);
        compare(one.frames, [{ x: 10, y: 20, width: 800, height: 600 }]);
        compare(one.planes[0].extent, viewport);
    }

    // Planes come in workspace order whatever the window order; each window keeps its own plane.
    function test_windowsGroupByWorkspaceInOrder() {
        let three = { id: 3, name: "3" }, one = { id: 1, name: "1" };
        let snap = WorkspacePlanes.snapshot([
            windowOn(three, [0, 0], [100, 100]),
            windowOn(one, [-2458, 0], [1255, 1440]),
            windowOn(three, [200, 0], [100, 100])
        ], viewport);
        compare(snap.planes.map(plane => plane.id), [1, 3]);
        compare(snap.planeOf, [1, 0, 1]);
        compare(snap.planes[1].frames.length, 2);
        compare(snap.planes[0].extent.x, -2458);
        compare(snap.nav.length, 3);
        verify(snap.nav[1].y < snap.nav[0].y, "the lower workspace's band comes first");
    }

    function test_unknownFramesAndMonitorsFallBack() {
        let fallback = { x: 0, y: 0, width: 1920, height: 1080 };
        let snap = WorkspacePlanes.snapshot([{ title: "w", lastIpcObject: {}, workspace: { id: 1, name: "1" }, monitor: null }], fallback);
        compare(snap.planes[0].viewport, fallback);
        compare(snap.frames[0], fallback);
    }

    function test_windowsWithoutAWorkspaceShareOnePlane() {
        let snap = WorkspacePlanes.snapshot([windowOn(null, [0, 0], [10, 10]), windowOn(null, [20, 0], [10, 10])], viewport);
        compare(snap.planes.length, 1);
        compare(snap.planes[0].id, 0);
        compare(snap.planeOf, [0, 0]);
    }

    function test_emptyWorkspaceIsItsViewport() {
        compare(WorkspacePlanes.extent(viewport, []), viewport);
    }

    function test_oneWindowInsideKeepsTheViewport() {
        compare(WorkspacePlanes.extent(viewport, [{ x: 100, y: 0, width: 1200, height: 1440 }]), viewport);
    }

    // A scrolling layout parks windows left of the monitor; the plane widens to hold them.
    function test_scrolledOffWindowsWidenThePlane() {
        let box = WorkspacePlanes.extent(viewport, [
            { x: -2458, y: 0, width: 1255, height: 1440 },
            { x: 1306, y: 0, width: 1254, height: 1440 },
            { x: 2000, y: -40, width: 900, height: 600 }
        ]);
        compare(box, { x: -2458, y: -40, width: 2900 + 2458, height: 1480 });
    }

    function test_windowsBelowTheMonitorDeepenThePlane() {
        compare(WorkspacePlanes.extent(viewport, [{ x: 100, y: 1000, width: 800, height: 800 }]), { x: 0, y: 0, width: 2560, height: 1800 });
    }

    function test_planeKeepsTheExtentShapeInsideTheBox() {
        let wide = WorkspacePlanes.fitPlane({ x: 0, y: 0, width: 5000, height: 1000 }, 1600, 800);
        compare(wide.width, 1600);
        fuzzyCompare(wide.width / wide.height, 5, 0.001);
        let tall = WorkspacePlanes.fitPlane({ x: 0, y: 0, width: 1000, height: 1000 }, 1600, 800);
        compare(tall.height, 800);
        let unknown = WorkspacePlanes.fitPlane({ x: 0, y: 0, width: 0, height: 0 }, 1600, 800);
        fuzzyCompare(unknown.width / unknown.height, 16 / 9, 0.001);
    }

    function test_windowsScaleOntoThePlane() {
        let box = { x: -1000, y: 0, width: 4000, height: 1000 };
        let rect = WorkspacePlanes.onPlane({ x: 1000, y: 500, width: 2000, height: 500 }, box, { width: 400, height: 100 });
        compare(rect, { x: 200, y: 50, width: 200, height: 50 });
    }

    function test_numberedWorkspacesFirstThenNamed() {
        let order = WorkspacePlanes.planeOrder([
            { id: 3, name: "3" }, { id: -98, name: "special:scratch" }, { id: 1, name: "1" }, { id: -99, name: "special:magic" }, { id: 10, name: "10" }
        ]);
        compare(order.map(w => w.id), [1, 3, 10, -99, -98]);
        compare(WorkspacePlanes.planeOrder([]).length, 0);
    }

    function test_leftAndRightStayOnThePlane() {
        compare(GridLayout.neighbourIndex(nav, 0, 1, 0), 1);
        compare(GridLayout.neighbourIndex(nav, 1, -1, 0), 0);
    }

    function test_downReachesTheWindowBelowBeforeTheNextPlane() {
        compare(GridLayout.neighbourIndex(nav, 0, 0, 1), 2);
        compare(GridLayout.neighbourIndex(nav, 2, 0, 1), 3);
        compare(GridLayout.neighbourIndex(nav, 3, 0, -1), 2);
    }

    // A portrait workspace: its band must not reach into the next plane's.
    function test_tallPlanesKeepTheirOwnBand() {
        let tall = { x: 0, y: 0, width: 1000, height: 2000 };
        let rects = WorkspacePlanes.navRects([
            { plane: 0, extent: tall, rect: { x: 0, y: 0, width: 1000, height: 400 } },
            { plane: 0, extent: tall, rect: { x: 0, y: 1500, width: 1000, height: 400 } },
            { plane: 1, extent: tall, rect: { x: 0, y: 0, width: 1000, height: 400 } }
        ]);
        compare(GridLayout.neighbourIndex(rects, 0, 0, 1), 1);
        compare(GridLayout.neighbourIndex(rects, 1, 0, 1), 2);
    }

    function test_upFromTheTopPlaneFindsNothing() {
        compare(GridLayout.neighbourIndex(nav, 0, 0, -1), -1);
        compare(GridLayout.neighbourIndex(nav, 1, 0, -1), -1);
    }

    // Plane 0: a and b side by side, c below a. Plane 1: d.
    readonly property var box: ({ x: 0, y: 0, width: 2000, height: 1000 })
    readonly property var nav: WorkspacePlanes.navRects([
        { plane: 0, extent: box, rect: { x: 0, y: 0, width: 900, height: 400 } },
        { plane: 0, extent: box, rect: { x: 1000, y: 0, width: 900, height: 400 } },
        { plane: 0, extent: box, rect: { x: 0, y: 500, width: 900, height: 400 } },
        { plane: 1, extent: box, rect: { x: 500, y: 0, width: 900, height: 900 } }
    ])

    function test_aShapelessBoxFitsAsWide() {
        let flat = WorkspacePlanes.fitPlane({ x: 0, y: 0, width: 1000, height: 0 }, 1600, 800);
        fuzzyCompare(flat.width / flat.height, 16 / 9, 0.001);
        let thin = WorkspacePlanes.fitPlane({ x: 0, y: 0, width: 0, height: 1000 }, 1600, 800);
        fuzzyCompare(thin.width / thin.height, 16 / 9, 0.001);
    }

    function test_anOffsetBoxMapsItsCornerToTheOrigin() {
        let box = { x: -1000, y: -500, width: 4000, height: 2000 };
        compare(WorkspacePlanes.onPlane({ x: -1000, y: -500, width: 2000, height: 1000 }, box, { width: 400, height: 200 }),
            { x: 0, y: 0, width: 200, height: 100 });
    }

    function test_aSizelessBoxCollapsesOntoTheCorner() {
        compare(WorkspacePlanes.onPlane({ x: 50, y: 70, width: 10, height: 10 }, { x: 0, y: 0, width: 0, height: 0 }, { width: 400, height: 200 }),
            { x: 0, y: 0, width: 0, height: 0 });
    }

    function test_unnumberedWorkspacesSortByName() {
        let order = WorkspacePlanes.planeOrder([{ id: -3, name: "c" }, { id: 2, name: "2" }, { id: 0, name: "a" }, { id: -1, name: "b" }]);
        compare(order.map(w => w.name), ["2", "a", "b", "c"]);
    }

    // Every plane's band is 1000 high whatever its extent, offset by 2000 per plane.
    function test_navRectsNormaliseEachPlane() {
        let rects = WorkspacePlanes.navRects([{ plane: 1, extent: { x: -1000, y: -500, width: 4000, height: 2000 }, rect: { x: 1000, y: 500, width: 2000, height: 1000 } }]);
        compare(rects, [{ x: 1000, y: 2500, width: 1000, height: 500 }]);
    }
}
