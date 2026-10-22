import QtQuick
import QtTest
import "../DioramaLayout.js" as DioramaLayout

TestCase {
    name: "DioramaLayout"

    function apply(m, x, y) { return { x: m[0] * x + m[1] * y + m[3], y: m[4] * x + m[5] * y + m[7] }; }

    function test_theOriginStaysPut() {
        compare(DioramaLayout.project(0, 0, 0), { x: 0, y: 0 });
    }

    // u runs right and down, v left and down, h straight up.
    function test_axesRunAsDrawn() {
        let u = DioramaLayout.project(100, 0, 0), v = DioramaLayout.project(0, 100, 0), h = DioramaLayout.project(0, 0, 100);
        verify(u.x > 0 && u.y > 0);
        verify(v.x < 0 && v.y > 0);
        compare(h, { x: 0, y: -100 });
        fuzzyCompare(u.x * u.x + (u.y / DioramaLayout.squash) * (u.y / DioramaLayout.squash), 10000, 0.01);
        fuzzyCompare(v.x * v.x + (v.y / DioramaLayout.squash) * (v.y / DioramaLayout.squash), 10000, 0.01);
        fuzzyCompare(Math.atan2(u.y / DioramaLayout.squash, u.x) * 180 / Math.PI, DioramaLayout.yaw, 0.0001);
    }

    function test_projectionIsLinear() {
        let a = DioramaLayout.project(30, 50, 10), b = DioramaLayout.project(70, -20, 5), sum = DioramaLayout.project(100, 30, 15);
        fuzzyCompare(a.x + b.x, sum.x, 0.0001);
        fuzzyCompare(a.y + b.y, sum.y, 0.0001);
    }

    function test_noSlabsNoPlaces() {
        compare(DioramaLayout.arrange([]), []);
    }

    function test_oneSlabSitsAtTheOrigin() {
        compare(DioramaLayout.arrange([{ x: -500, y: 0, width: 3000, height: 1440 }]), [{ u: 0, v: 0 }]);
    }

    // Four slabs make a 2x2 grid of cells the largest extent's size plus the gap.
    function test_slabsFillAGridOfEqualCells() {
        let places = DioramaLayout.arrange([
            { x: 0, y: 0, width: 2560, height: 1440 }, { x: 0, y: 0, width: 1000, height: 1000 },
            { x: 0, y: 0, width: 4000, height: 1440 }, { x: 0, y: 0, width: 2560, height: 1440 }
        ]);
        let gap = 4000 * DioramaLayout.gapFraction;
        compare(places, [{ u: 0, v: 0 }, { u: 4000 + gap, v: 0 }, { u: 0, v: 1440 + gap }, { u: 4000 + gap, v: 1440 + gap }]);
    }

    function test_threeSlabsWrapAfterTwo() {
        let places = DioramaLayout.arrange([{ x: 0, y: 0, width: 100, height: 100 }, { x: 0, y: 0, width: 100, height: 100 }, { x: 0, y: 0, width: 100, height: 100 }]);
        compare(places.map(p => p.v > 0), [false, false, true]);
    }

    function test_windowsKeepTheirPlaceOnTheSlab() {
        compare(DioramaLayout.onFloor({ x: -2458, y: 10, width: 1255, height: 1400 }, { x: -2458, y: -40, width: 5018, height: 1480 }, { u: 600, v: 300 }),
            { u: 600, v: 350, width: 1255, depth: 1400 });
    }

    function test_cornersAreTheProjectedRect() {
        let floor = { u: 10, v: 20, width: 300, depth: 200 };
        let points = DioramaLayout.corners(floor, 40);
        compare(points[0], DioramaLayout.project(10, 20, 40));
        compare(points[1], DioramaLayout.project(310, 20, 40));
        compare(points[2], DioramaLayout.project(10, 220, 40));
        compare(points[3], DioramaLayout.project(310, 220, 40));
    }

    function test_boundsOfNothingIsEmpty() {
        compare(DioramaLayout.bounds([]), { x: 0, y: 0, width: 0, height: 0 });
    }

    function test_boundsOfOnePointIsThatPoint() {
        compare(DioramaLayout.bounds([{ x: 3, y: -4 }]), { x: 3, y: -4, width: 0, height: 0 });
    }

    function test_boundsHoldEveryPoint() {
        compare(DioramaLayout.bounds([{ x: 3, y: -4 }, { x: -2, y: 7 }, { x: 10, y: 0 }]), { x: -2, y: -4, width: 12, height: 11 });
    }

    // A box twice the area's aspect is limited by width and centred vertically.
    function test_fitCentresTheModel() {
        let view = DioramaLayout.fit({ x: -100, y: 50, width: 400, height: 100 }, 800, 400);
        compare(view.scale, 2);
        compare(DioramaLayout.toScreen({ x: -100, y: 50 }, view), { x: 0, y: 100 });
        compare(DioramaLayout.toScreen({ x: 300, y: 150 }, view), { x: 800, y: 300 });
    }

    function test_fitLimitedByHeight() {
        let view = DioramaLayout.fit({ x: 0, y: 0, width: 100, height: 400 }, 800, 400);
        compare(view.scale, 1);
        compare(view.x, 350);
        compare(view.y, 0);
    }

    function test_anEmptyModelFitsAtScaleOne() {
        compare(DioramaLayout.fit({ x: 0, y: 0, width: 0, height: 0 }, 800, 400).scale, 1);
        compare(DioramaLayout.fit({ x: 0, y: 0, width: 100, height: 0 }, 800, 400).scale, 1);
        compare(DioramaLayout.fit({ x: 0, y: 0, width: 0, height: 100 }, 800, 400).scale, 1);
    }

    function test_faceMatrixMapsTheItemOntoTheParallelogram() {
        let p0 = { x: 10, y: 20 }, px = { x: 110, y: 70 }, py = { x: -30, y: 100 };
        let m = DioramaLayout.faceMatrix(p0, px, py, 200, 50);
        compare(apply(m, 0, 0), p0);
        compare(apply(m, 200, 0), px);
        compare(apply(m, 0, 50), py);
        compare([m[2], m[6]], [0, 0]);
        compare(m.slice(8), [0, 0, 1, 0, 0, 0, 0, 1]);
    }

    function test_aSizelessFaceStaysFinite() {
        verify(DioramaLayout.faceMatrix({ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 0, y: 1 }, 0, 0).every(isFinite));
    }

    function test_nearerFloorsDrawLater() {
        let back = { u: 0, v: 0, width: 100, depth: 100 };
        verify(DioramaLayout.depthOf({ u: 200, v: 0, width: 100, depth: 100 }) > DioramaLayout.depthOf(back));
        verify(DioramaLayout.depthOf({ u: 0, v: 200, width: 100, depth: 100 }) > DioramaLayout.depthOf(back));
        compare(DioramaLayout.depthOf(back), DioramaLayout.project(50, 50, 0).y);
    }
}
