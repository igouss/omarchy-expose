import QtQuick
import QtTest
import "../AtlasLayout.js" as AtlasLayout

TestCase {
    name: "AtlasLayout"

    function test_noWorkspacesNoPlaces() {
        compare(AtlasLayout.arrange([]), []);
    }

    function test_oneWorkspaceAtTheOrigin() {
        compare(AtlasLayout.arrange([{ x: -2458, y: 0, width: 5018, height: 1440 }]), [{ x: 0, y: 0 }]);
    }

    // Side by side, each after the last one's width and a gap scaled from the tallest.
    function test_workspacesLieSideBySide() {
        let gap = 1600 * AtlasLayout.gapFraction;
        compare(AtlasLayout.arrange([
            { x: -2458, y: 0, width: 5018, height: 1440 },
            { x: 0, y: 0, width: 2560, height: 1600 },
            { x: 0, y: 0, width: 1000, height: 500 }
        ]), [{ x: 0, y: 0 }, { x: 5018 + gap, y: 0 }, { x: 5018 + 2560 + 2 * gap, y: 0 }]);
    }

    function test_windowsKeepTheirPlaceOnTheMap() {
        compare(AtlasLayout.onMap({ x: -2458, y: 10, width: 1255, height: 1400 }, { x: -2458, y: -40, width: 5018, height: 1480 }, { x: 3000, y: 0 }),
            { x: 3000, y: 50, width: 1255, height: 1400 });
    }

    function test_unionOfNothingIsNull() {
        compare(AtlasLayout.union([]), null);
    }

    function test_unionOfOneIsItself() {
        compare(AtlasLayout.union([{ x: 1, y: 2, width: 3, height: 4 }]), { x: 1, y: 2, width: 3, height: 4 });
    }

    function test_unionHoldsEveryRect() {
        compare(AtlasLayout.union([{ x: 0, y: 0, width: 10, height: 10 }, { x: -5, y: 20, width: 10, height: 5 }, { x: 30, y: -2, width: 1, height: 1 }]),
            { x: -5, y: -2, width: 36, height: 27 });
    }

    // A wide rect is limited by the width, with the margin on both sides.
    function test_frameCentresTheRectWithAMargin() {
        let camera = AtlasLayout.frame({ x: 100, y: 200, width: 1000, height: 100 }, 2000, 1000);
        compare(camera.x, 600);
        compare(camera.y, 250);
        fuzzyCompare(camera.zoom, 2000 / (1000 * (1 + 2 * AtlasLayout.margin)), 1e-9);
        let shown = AtlasLayout.toScreen({ x: 100, y: 200, width: 1000, height: 100 }, camera, 2000, 1000);
        fuzzyCompare(shown.x, 2000 - shown.x - shown.width, 1e-6);
        fuzzyCompare(shown.x, 2000 * AtlasLayout.margin / (1 + 2 * AtlasLayout.margin), 1e-6);
    }

    function test_frameLimitedByHeight() {
        let camera = AtlasLayout.frame({ x: 0, y: 0, width: 100, height: 1000 }, 2000, 1000);
        fuzzyCompare(camera.zoom, 1000 / (1000 * (1 + 2 * AtlasLayout.margin)), 1e-9);
    }

    function test_frameZoomsInNoFurtherThanTheCap() {
        compare(AtlasLayout.frame({ x: 0, y: 0, width: 100, height: 100 }, 2000, 1000, 0.4).zoom, 0.4);
        fuzzyCompare(AtlasLayout.frame({ x: 0, y: 0, width: 10000, height: 100 }, 2000, 1000, 0.4).zoom, 2000 / (10000 * (1 + 2 * AtlasLayout.margin)), 1e-9);
    }

    function test_anAreaNotLaidOutKeepsAPositiveZoom() {
        compare(AtlasLayout.frame({ x: 0, y: 0, width: 100, height: 100 }, 1000, 0).zoom, AtlasLayout.minZoom);
        compare(AtlasLayout.frame({ x: 0, y: 0, width: 100, height: 100 }, 0, 0, 0.4).zoom, AtlasLayout.minZoom);
    }

    function test_aSizelessRectStillFrames() {
        let camera = AtlasLayout.frame({ x: 5, y: 5, width: 0, height: 0 }, 2000, 1000);
        verify(isFinite(camera.zoom) && camera.zoom > 0);
    }

    function test_theCameraCentreIsTheScreenCentre() {
        compare(AtlasLayout.toScreen({ x: 300, y: 400, width: 10, height: 20 }, { x: 300, y: 400, zoom: 2 }, 1000, 800),
            { x: 500, y: 400, width: 20, height: 40 });
        compare(AtlasLayout.toScreen({ x: 290, y: 410, width: 10, height: 20 }, { x: 300, y: 400, zoom: 2 }, 1000, 800),
            { x: 480, y: 420, width: 20, height: 40 });
    }

    function test_onScreenMeansOverlappingTheArea() {
        verify(AtlasLayout.onScreen({ x: -10, y: -10, width: 11, height: 11 }, 100, 100));
        verify(AtlasLayout.onScreen({ x: 99, y: 99, width: 10, height: 10 }, 100, 100));
        verify(!AtlasLayout.onScreen({ x: -10, y: 0, width: 10, height: 10 }, 100, 100));
        verify(!AtlasLayout.onScreen({ x: 0, y: -10, width: 10, height: 10 }, 100, 100));
        verify(!AtlasLayout.onScreen({ x: 100, y: 0, width: 10, height: 10 }, 100, 100));
        verify(!AtlasLayout.onScreen({ x: 0, y: 100, width: 10, height: 10 }, 100, 100));
    }

    function test_niceStepsAreOneTwoOrFive() {
        compare(AtlasLayout.niceStep(1), 1);
        compare(AtlasLayout.niceStep(1.2), 2);
        compare(AtlasLayout.niceStep(3), 5);
        compare(AtlasLayout.niceStep(7), 10);
        compare(AtlasLayout.niceStep(130), 200);
        compare(AtlasLayout.niceStep(500), 500);
        compare(AtlasLayout.niceStep(501), 1000);
        fuzzyCompare(AtlasLayout.niceStep(0.03), 0.05, 1e-12);
    }

    // At zoom 0.1 lines 60 px apart need 600 map px, so the step is 1000 (100 px on screen).
    function test_gridLinesAreEvenAndCoverTheArea() {
        let grid = AtlasLayout.gridLines({ x: 0, y: 0, zoom: 0.1 }, 1000, 500, 60);
        compare(grid.step, 1000);
        compare(grid.xs, [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]);
        compare(grid.ys, [50, 150, 250, 350, 450]);
    }

    function test_gridLinesFollowTheCamera() {
        let grid = AtlasLayout.gridLines({ x: 250, y: 0, zoom: 0.1 }, 1000, 500, 60);
        compare(grid.xs[0], 75);
        compare(grid.xs[1] - grid.xs[0], 100);
    }

    function test_aDegenerateCameraDrawsFewLines() {
        verify(AtlasLayout.gridLines({ x: 0, y: 0, zoom: 1e-12 }, 1000, 500, 60).xs.length <= AtlasLayout.maxLines);
        compare(AtlasLayout.gridLines({ x: 0, y: 0, zoom: NaN }, 1000, 500, 60).xs, []);
        verify(AtlasLayout.gridLines({ x: 0, y: 0, zoom: 1e9 }, 1000, 500, 1e-9).xs.length <= AtlasLayout.maxLines);
    }
}
