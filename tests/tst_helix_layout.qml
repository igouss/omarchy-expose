import QtQuick
import QtTest
import "../HelixLayout.js" as HelixLayout

TestCase {
    name: "HelixLayout"

    function place(offset) { return HelixLayout.placeFloor(offset, 2000, 1000, 400); }

    function test_theFrontFloorIsCentredFullAndUnturned() {
        let front = place(0);
        compare(front.centreX, 1000);
        compare(front.centreY, 1000 * HelixLayout.centreYFraction);
        compare(front.scale, 1);
        compare(front.turn, 0);
        compare(front.angle, HelixLayout.layBack);
        compare(front.depth, 0);
        compare(front.shade, 0);
        compare(front.opacity, 1);
    }

    // Floors on either side mirror each other: same depth, height step, opposite side and turn.
    function test_neighboursMirror() {
        let after = place(1), before = place(-1);
        fuzzyCompare(after.centreX - 1000, 1000 - before.centreX, 1e-9);
        fuzzyCompare(after.centreY - 400, 400 - before.centreY, 1e-9);
        compare(after.turn, -before.turn);
        fuzzyCompare(after.depth, before.depth, 1e-9);
        compare(after.turn, HelixLayout.stepAngle);
    }

    // The next floor is a step around the spine: radius * sin, radius * (1 - cos), seen in perspective.
    function test_theNextFloorSitsOnTheCircle() {
        let radius = 2000 * HelixLayout.radiusFraction;
        let theta = HelixLayout.stepAngle * Math.PI / 180;
        let next = place(1);
        fuzzyCompare(next.depth, radius * (1 - Math.cos(theta)), 1e-9);
        fuzzyCompare(next.scale, HelixLayout.focalFactor / (HelixLayout.focalFactor + 1 - Math.cos(theta)), 1e-9);
        fuzzyCompare(next.centreX, 1000 + radius * Math.sin(theta) * next.scale, 1e-9);
        fuzzyCompare(next.centreY, 400 + 400 * HelixLayout.pitchFactor * next.scale, 1e-9);
    }

    function test_floorsFurtherRoundAreDeeperSmallerDarkerAndBehind() {
        let a = place(0), b = place(1), c = place(2);
        verify(a.depth < b.depth && b.depth < c.depth);
        verify(a.scale > b.scale && b.scale > c.scale);
        verify(a.shade < b.shade && b.shade < c.shade);
        verify(a.z > b.z && b.z > c.z);
    }

    function test_floorsDescendWithTheOffset() {
        verify(place(1).centreY > place(0).centreY);
        verify(place(2).centreY > place(1).centreY);
    }

    function test_floorsMoveContinuously() {
        let before = place(0.999), after = place(1.001);
        verify(Math.abs(after.centreX - before.centreX) < 2);
        verify(Math.abs(after.centreY - before.centreY) < 2);
    }

    function test_floorsBeyondTheReachFadeOut() {
        compare(place(HelixLayout.reach).opacity, 1);
        compare(place(HelixLayout.reach + 0.5).opacity, 0.5);
        compare(place(-HelixLayout.reach - 1).opacity, 0);
    }

    // The spine stands at the radius: behind floors less than a quarter turn round, in front of the rest.
    function test_theSpineSplitsTheFloors() {
        let spine = HelixLayout.spineZ(2000);
        compare(spine, -Math.round(2000 * HelixLayout.radiusFraction));
        verify(place(1).z > spine);
        verify(place(2).z < spine);
    }

    function test_aWidthlessAreaStaysFinite() {
        let floor = HelixLayout.placeFloor(1, 0, 0, 0);
        verify(isFinite(floor.scale) && isFinite(floor.centreX) && isFinite(floor.centreY));
    }

    function test_aFloorHalfWayRoundIsFullyShaded() {
        fuzzyCompare(place(180 / HelixLayout.stepAngle).shade, 0.6, 1e-9);
    }
}
