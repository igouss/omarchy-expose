import QtQuick
import QtTest
import "../CarouselLayout.js" as CarouselLayout
import "../GridLayout.js" as GridLayout

TestCase {
    name: "CarouselLayout"

    readonly property int areaWidth: 2560
    readonly property int areaHeight: 1300
    readonly property var fiveRatios: [1.6, 0.6, 2.4, 1.0, 1.33]

    function centreX(rect) { return rect.x + rect.width / 2; }
    function centreY(rect) { return rect.y + rect.height / 2; }

    function test_noWindowsOrNoSpaceLaysOutNothing() {
        compare(CarouselLayout.layout([], 0, areaWidth, areaHeight).length, 0);
        compare(CarouselLayout.layout([1.6], 0, 0, areaHeight).length, 0);
        compare(CarouselLayout.layout([1.6], 0, areaWidth, -1).length, 0);
    }

    function test_oneWindowSitsFrontAndCentre() {
        let placed = CarouselLayout.place(0, 1.6, areaWidth, areaHeight);
        fuzzyCompare(centreX(placed), areaWidth / 2, 0.001);
        compare(placed.angle, 0);
        compare(placed.scale, 1);
        compare(placed.shade, 0);
        compare(placed.opacity, 1);
        fuzzyCompare(placed.width / placed.height, 1.6, 0.001);
    }

    function test_noSelectionCentresTheFirstWindow() {
        let rects = CarouselLayout.layout([1.6, 1.6], -1, areaWidth, areaHeight);
        fuzzyCompare(centreX(rects[0]), areaWidth / 2, 0.001);
    }

    function test_sidesMirrorEachOther() {
        let left = CarouselLayout.place(-2, 1.6, areaWidth, areaHeight);
        let right = CarouselLayout.place(2, 1.6, areaWidth, areaHeight);
        fuzzyCompare(centreX(left) + centreX(right), areaWidth, 0.001);
        compare(left.angle, -right.angle);
        compare(left.z, right.z);
        verify(left.angle > 0, "left cards turn to face the centre");
    }

    function test_frontCardDrawsOverItsNeighbours() {
        let front = CarouselLayout.place(0, 1.6, areaWidth, areaHeight);
        let near = CarouselLayout.place(1, 1.6, areaWidth, areaHeight);
        let far = CarouselLayout.place(3, 1.6, areaWidth, areaHeight);
        verify(front.z > near.z && near.z > far.z, "stacking falls off with distance");
    }

    function test_farCardsTurnNoFurtherThanTheFirstSideCard() {
        let first = CarouselLayout.place(1, 1.6, areaWidth, areaHeight);
        let far = CarouselLayout.place(3, 1.6, areaWidth, areaHeight);
        compare(far.angle, first.angle);
        compare(far.scale, first.scale);
        compare(far.shade, first.shade);
    }

    // The spring passes through every offset; the arc must not jump on the way.
    function test_cardsMoveContinuouslyThroughTheFirstSideSlot() {
        let before = CarouselLayout.place(0.999, 1.6, areaWidth, areaHeight);
        let after = CarouselLayout.place(1.001, 1.6, areaWidth, areaHeight);
        verify(Math.abs(centreX(after) - centreX(before)) < 2, "no jump at offset 1");
    }

    function test_fadingCardsDrawBehindTheLastVisibleOne() {
        let last = CarouselLayout.place(CarouselLayout.reach, 1.6, areaWidth, areaHeight);
        let fading = CarouselLayout.place(CarouselLayout.reach + 0.5, 1.6, areaWidth, areaHeight);
        verify(last.z > fading.z, "fading card stacks behind");
    }

    function test_unknownShapeFallsBackToWidescreen() {
        let placed = CarouselLayout.place(0, 0, areaWidth, areaHeight);
        fuzzyCompare(placed.width / placed.height, 16 / 9, 0.001);
    }

    function test_cardsBeyondTheReachFadeOut() {
        compare(CarouselLayout.place(CarouselLayout.reach, 1.6, areaWidth, areaHeight).opacity, 1);
        compare(CarouselLayout.place(CarouselLayout.reach + 1, 1.6, areaWidth, areaHeight).opacity, 0);
    }

    function test_extremeShapesStayInsideTheBox() {
        let wide = CarouselLayout.place(0, 8, areaWidth, areaHeight);
        let tall = CarouselLayout.place(0, 0.2, areaWidth, areaHeight);
        verify(wide.width <= areaWidth * CarouselLayout.boxWidthFraction + 0.001, "wide window limited by width");
        verify(tall.height <= areaHeight * CarouselLayout.boxHeightFraction + 0.001, "tall window limited by height");
        fuzzyCompare(wide.width / wide.height, 8, 0.001);
        fuzzyCompare(tall.width / tall.height, 0.2, 0.001);
    }

    function increasing(values) {
        return values.every((value, index) => index === 0 || value > values[index - 1]);
    }

    // Centres strictly increase on one line during an animation as well.
    readonly property var sweep: [-6.25, -5, -1.5, -1, -0.75, -0.25, 0, 0.25, 0.75, 1, 1.5, 5, 6.25]

    function test_centresIncreaseOnOneLineAtFractionalOffsets() {
        let placed = sweep.map(offset => CarouselLayout.place(offset, 1, areaWidth, areaHeight));
        verify(increasing(placed.map(rect => centreX(rect))), "centres increase with the offset");
        verify(placed.every(rect => Math.abs(centreY(rect) - centreY(placed[0])) < 0.001), "centres share one line");
    }

    function test_arrowsStepToTheAdjacentWindowFromTheMiddle() {
        let rects = CarouselLayout.layout(fiveRatios, 2, areaWidth, areaHeight);
        compare(GridLayout.neighbourIndex(rects, 2, 1, 0), 3);
        compare(GridLayout.neighbourIndex(rects, 2, -1, 0), 1);
        compare(GridLayout.neighbourIndex(rects, 2, 0, 1), -1);
        compare(GridLayout.neighbourIndex(rects, 2, 0, -1), -1);
    }

    function test_arrowsStopAtTheEnds() {
        let first = CarouselLayout.layout(fiveRatios, 0, areaWidth, areaHeight);
        compare(GridLayout.neighbourIndex(first, 0, -1, 0), -1);
        compare(GridLayout.neighbourIndex(first, 0, 1, 0), 1);
        let last = CarouselLayout.layout(fiveRatios, 4, areaWidth, areaHeight);
        compare(GridLayout.neighbourIndex(last, 4, 1, 0), -1);
        compare(GridLayout.neighbourIndex(last, 4, -1, 0), 3);
    }

    // Beyond the reach, cards still order strictly, so no offscreen tie.
    function test_arrowsStepPastTheReach() {
        let ratios = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
        let rects = CarouselLayout.layout(ratios, 0, areaWidth, areaHeight);
        compare(GridLayout.neighbourIndex(rects, 9, 1, 0), 10);
        compare(GridLayout.neighbourIndex(rects, 10, -1, 0), 9);
    }
}
