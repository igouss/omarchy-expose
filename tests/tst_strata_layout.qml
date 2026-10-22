import QtQuick
import QtTest
import "../StrataLayout.js" as StrataLayout

TestCase {
    name: "StrataLayout"


    function increasing(values) {
        return values.every((value, index) => index === 0 || value > values[index - 1]);
    }

    function test_farPlanesLieBackNoFurtherThanTheNextOne() {
        let next = StrataLayout.placePlane(1, 1300, 600);
        let far = StrataLayout.placePlane(2, 1300, 600);
        compare(far.angle, StrataLayout.backAngle);
        compare(far.shade, next.shade);
    }

    function test_theFrontPlaneIsCentredAndLeastLaidBack() {
        let front = StrataLayout.placePlane(0, 1300, 600);
        let next = StrataLayout.placePlane(1, 1300, 600);
        fuzzyCompare(front.centreY, 1300 * StrataLayout.centreYFraction, 0.001);
        compare(front.angle, StrataLayout.frontAngle);
        compare(front.turn, 0);
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
}
