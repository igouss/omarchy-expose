import QtQuick
import QtTest
import "../StrataLayout.js" as StrataLayout
import "../GridLayout.js" as GridLayout

TestCase {
    name: "StrataLayout"

    readonly property var viewport: ({ x: 0, y: 0, width: 2560, height: 1440 })

    function centreY(rect) { return rect.y + rect.height / 2; }

    function increasing(values) {
        return values.every((value, index) => index === 0 || value > values[index - 1]);
    }

    function test_emptyWorkspaceIsItsViewport() {
        compare(StrataLayout.extent(viewport, []), viewport);
    }

    function test_oneWindowInsideKeepsTheViewport() {
        compare(StrataLayout.extent(viewport, [{ x: 100, y: 0, width: 1200, height: 1440 }]), viewport);
    }

    // A scrolling layout parks windows left of the monitor; the plane widens to hold them.
    function test_scrolledOffWindowsWidenThePlane() {
        let box = StrataLayout.extent(viewport, [
            { x: -2458, y: 0, width: 1255, height: 1440 },
            { x: 1306, y: 0, width: 1254, height: 1440 },
            { x: 2000, y: -40, width: 900, height: 600 }
        ]);
        compare(box, { x: -2458, y: -40, width: 2900 + 2458, height: 1480 });
    }

    function test_windowsBelowTheMonitorDeepenThePlane() {
        compare(StrataLayout.extent(viewport, [{ x: 100, y: 1000, width: 800, height: 800 }]), { x: 0, y: 0, width: 2560, height: 1800 });
    }

    function test_farPlanesLieBackNoFurtherThanTheNextOne() {
        let next = StrataLayout.placePlane(1, 1300, 600);
        let far = StrataLayout.placePlane(2, 1300, 600);
        compare(far.angle, StrataLayout.backAngle);
        compare(far.shade, next.shade);
    }

    function test_planeKeepsTheExtentShapeInsideTheBox() {
        let wide = StrataLayout.fitPlane({ x: 0, y: 0, width: 5000, height: 1000 }, 1600, 800);
        compare(wide.width, 1600);
        fuzzyCompare(wide.width / wide.height, 5, 0.001);
        let tall = StrataLayout.fitPlane({ x: 0, y: 0, width: 1000, height: 1000 }, 1600, 800);
        compare(tall.height, 800);
        let unknown = StrataLayout.fitPlane({ x: 0, y: 0, width: 0, height: 0 }, 1600, 800);
        fuzzyCompare(unknown.width / unknown.height, 16 / 9, 0.001);
    }

    function test_windowsScaleOntoThePlane() {
        let box = { x: -1000, y: 0, width: 4000, height: 1000 };
        let rect = StrataLayout.onPlane({ x: 1000, y: 500, width: 2000, height: 500 }, box, { width: 400, height: 100 });
        compare(rect, { x: 200, y: 50, width: 200, height: 50 });
    }

    function test_theFrontPlaneIsCentredAndLeastLaidBack() {
        let front = StrataLayout.placePlane(0, 1300, 600);
        let next = StrataLayout.placePlane(1, 1300, 600);
        fuzzyCompare(front.centreY, 1300 * StrataLayout.centreYFraction, 0.001);
        compare(front.angle, StrataLayout.frontAngle);
        compare(next.angle, StrataLayout.backAngle);
        verify(front.z > next.z && front.scale > next.scale && front.shade < next.shade);
    }

    function test_planesStackInOrderAndMirror() {
        let offsets = [-3, -1.5, -1, -0.5, 0, 0.5, 1, 1.5, 3];
        verify(increasing(offsets.map(offset => StrataLayout.placePlane(offset, 1300, 600).centreY)), "planes stack downward with the offset");
        let above = StrataLayout.placePlane(-2, 1300, 600);
        let below = StrataLayout.placePlane(2, 1300, 600);
        fuzzyCompare(above.centreY + below.centreY, 2 * 1300 * StrataLayout.centreYFraction, 0.001);
    }

    function test_planesMoveContinuouslyThroughTheFirstStep() {
        let before = StrataLayout.placePlane(0.999, 1300, 600);
        let after = StrataLayout.placePlane(1.001, 1300, 600);
        verify(Math.abs(after.centreY - before.centreY) < 2, "no jump at offset 1");
    }

    function test_planesBeyondTheReachFadeOut() {
        compare(StrataLayout.placePlane(StrataLayout.reach, 1300, 600).opacity, 1);
        compare(StrataLayout.placePlane(StrataLayout.reach + 1, 1300, 600).opacity, 0);
        verify(StrataLayout.placePlane(StrataLayout.reach, 1300, 600).z > StrataLayout.placePlane(StrataLayout.reach + 0.5, 1300, 600).z);
    }

    function test_numberedWorkspacesFirstThenNamed() {
        let order = StrataLayout.planeOrder([
            { id: 3, name: "3" }, { id: -98, name: "special:scratch" }, { id: 1, name: "1" }, { id: -99, name: "special:magic" }, { id: 10, name: "10" }
        ]);
        compare(order.map(w => w.id), [1, 3, 10, -99, -98]);
        compare(StrataLayout.planeOrder([]).length, 0);
    }

    // Plane 0: a and b side by side, c below a. Plane 1: d.
    readonly property var box: ({ x: 0, y: 0, width: 2000, height: 1000 })
    readonly property var nav: StrataLayout.navRects([
        { plane: 0, extent: box, rect: { x: 0, y: 0, width: 900, height: 400 } },
        { plane: 0, extent: box, rect: { x: 1000, y: 0, width: 900, height: 400 } },
        { plane: 0, extent: box, rect: { x: 0, y: 500, width: 900, height: 400 } },
        { plane: 1, extent: box, rect: { x: 500, y: 0, width: 900, height: 900 } }
    ])

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
        let rects = StrataLayout.navRects([
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
}
