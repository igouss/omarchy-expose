import QtQuick
import QtTest
import "../TimeLayout.js" as TimeLayout
import "../GridLayout.js" as GridLayout

TestCase {
    name: "TimeLayout"

    function centreX(placed) { return placed.x + placed.width / 2; }
    function centreY(placed) { return placed.y + placed.height / 2; }

    function test_noWindowsNoRanks() {
        compare(TimeLayout.ranks([]), []);
    }

    function test_oneWindowRanksFirst() {
        compare(TimeLayout.ranks([7]), [0]);
    }

    function test_lowerHistoryIdsRankFirst() {
        compare(TimeLayout.ranks([3, 0, 5, 1]), [2, 0, 3, 1]);
    }

    function test_windowsWithoutHistoryFollowInListOrder() {
        compare(TimeLayout.ranks([-1, 2, -1, 0]), [2, 1, 3, 0]);
    }

    function test_equalIdsKeepListOrder() {
        compare(TimeLayout.ranks([1, 1, 0]), [1, 2, 0]);
    }

    function test_theFrontCardIsCentredAndFull() {
        let front = TimeLayout.place(0, 16 / 9, 2000, 1000);
        compare(front.scale, 1);
        compare(centreX(front), 1000);
        compare(centreY(front), 1000 * TimeLayout.frontYFraction);
        compare(front.opacity, 1);
        compare(front.shade, 0);
    }

    function test_aRatioOfZeroFallsBackToWide() {
        let front = TimeLayout.place(0, 0, 2000, 1000);
        fuzzyCompare(front.width / front.height, 16 / 9, 0.001);
    }

    // Perspective: a card `depth` ranks back is drawn 1 / (1 + depthStep * depth) as large.
    function test_scaleFollowsPerspectiveBetweenRanks() {
        fuzzyCompare(TimeLayout.place(0.5, 1.6, 2000, 1000).scale * (1 + TimeLayout.depthStep * 0.5), 1, 0.0001);
        fuzzyCompare(TimeLayout.place(3, 1.6, 2000, 1000).scale * (1 + TimeLayout.depthStep * 3), 1, 0.0001);
    }

    function test_cardsBetweenRanksAreFullyOpaque() {
        compare(TimeLayout.place(0.5, 1.6, 2000, 1000).opacity, 1);
    }

    function test_theFrontCardFitsItsBox() {
        let wide = TimeLayout.place(0, 4, 2000, 1000);
        compare(wide.width, 2000 * TimeLayout.boxWidthFraction);
        let tall = TimeLayout.place(0, 0.5, 2000, 1000);
        compare(tall.height, 1000 * TimeLayout.boxHeightFraction);
        fuzzyCompare(tall.width / tall.height, 0.5, 0.001);
    }

    // Deeper cards are smaller, higher, darker, and drawn behind.
    function test_olderCardsRecedeTowardTheVanishingPoint() {
        let a = TimeLayout.place(0, 1.6, 2000, 1000);
        let b = TimeLayout.place(1, 1.6, 2000, 1000);
        let c = TimeLayout.place(2, 1.6, 2000, 1000);
        verify(a.scale > b.scale && b.scale > c.scale);
        verify(centreY(a) > centreY(b) && centreY(b) > centreY(c));
        verify(centreY(c) > 1000 * TimeLayout.vanishYFraction);
        verify(a.z > b.z && b.z > c.z);
        verify(a.shade < b.shade && b.shade < c.shade);
        compare(centreX(c), 1000);
        fuzzyCompare(centreY(c) - 1000 * TimeLayout.vanishYFraction,
            (1000 * (TimeLayout.frontYFraction - TimeLayout.vanishYFraction)) * c.scale, 0.001);
    }

    function test_cardsMoveContinuouslyThroughTheFront() {
        let before = TimeLayout.place(-0.001, 1.6, 2000, 1000);
        let after = TimeLayout.place(0.001, 1.6, 2000, 1000);
        fuzzyCompare(before.scale, after.scale, 0.002);
        fuzzyCompare(centreY(before), centreY(after), 1);
    }

    // Newer windows than the selection fly past the viewer and fade.
    function test_newerCardsGrowAndFadeOut() {
        let passing = TimeLayout.place(-0.25, 1.6, 2000, 1000);
        verify(passing.scale > 1);
        compare(passing.opacity, 0.5);
        compare(TimeLayout.place(-0.5, 1.6, 2000, 1000).opacity, 0);
        verify(passing.z > TimeLayout.place(0, 1.6, 2000, 1000).z);
    }

    function test_cardsBeyondTheReachFadeOut() {
        compare(TimeLayout.place(TimeLayout.reach, 1.6, 2000, 1000).opacity, 1);
        compare(TimeLayout.place(TimeLayout.reach + 0.5, 1.6, 2000, 1000).opacity, 0.5);
        compare(TimeLayout.place(TimeLayout.reach + 1, 1.6, 2000, 1000).opacity, 0);
    }

    function test_shadeStopsDeepening() {
        compare(TimeLayout.place(5, 1.6, 2000, 1000).shade, 0.6);
        compare(TimeLayout.place(9, 1.6, 2000, 1000).shade, 0.6);
    }

    readonly property var nav: TimeLayout.navRects([2, 0, 1])

    function test_upStepsBackInTime() {
        compare(GridLayout.neighbourIndex(nav, 1, 0, -1), 2);
        compare(GridLayout.neighbourIndex(nav, 2, 0, -1), 0);
    }

    function test_downStepsForwardInTime() {
        compare(GridLayout.neighbourIndex(nav, 0, 0, 1), 2);
        compare(GridLayout.neighbourIndex(nav, 2, 0, 1), 1);
    }

    function test_theEndsOfTimeFindNothing() {
        compare(GridLayout.neighbourIndex(nav, 0, 0, -1), -1);
        compare(GridLayout.neighbourIndex(nav, 1, 0, 1), -1);
        compare(GridLayout.neighbourIndex(nav, 1, 1, 0), -1);
    }

    function test_starsWrapAroundTheTunnel() {
        let a = TimeLayout.star(5, 1.25, 8, 2000, 1000);
        let b = TimeLayout.star(5, 9.25, 8, 2000, 1000);
        fuzzyCompare(a.x, b.x, 0.001);
        fuzzyCompare(a.y, b.y, 0.001);
    }

    function test_starsApproachAsTheCameraTravels() {
        let far = TimeLayout.star(3, 0, 8, 2000, 1000);
        let nearer = TimeLayout.star(3, 0.5, 8, 2000, 1000);
        verify(far.depth > 0.5);
        fuzzyCompare(nearer.depth, far.depth - 0.5, 0.0001);
        verify(nearer.size > far.size);
    }

    // Stars lie on rays from the vanishing point and spread out as they approach.
    function test_starsSpreadFromTheVanishingPoint() {
        let far = TimeLayout.star(3, 0, 8, 2000, 1000);
        let nearer = TimeLayout.star(3, 0.5, 8, 2000, 1000);
        let vanishY = 1000 * TimeLayout.vanishYFraction;
        let ratio = TimeLayout.scaleAt(nearer.depth) / TimeLayout.scaleAt(far.depth);
        fuzzyCompare(nearer.x - 1000, (far.x - 1000) * ratio, 0.001);
        fuzzyCompare(nearer.y - vanishY, (far.y - vanishY) * ratio, 0.001);
        compare(nearer.size, 1 + 3 * TimeLayout.scaleAt(nearer.depth));
    }

    function test_starsFadeAtBothEndsOfTheTunnel() {
        let star = TimeLayout.star(3, 0, 8, 2000, 1000);
        compare(TimeLayout.star(3, star.depth, 8, 2000, 1000).opacity, 0);
        verify(TimeLayout.star(3, star.depth - 0.1, 8, 2000, 1000).opacity < 0.2);
        verify(TimeLayout.star(3, star.depth - 7.95, 8, 2000, 1000).opacity < 0.15);
    }
}
