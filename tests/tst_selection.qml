import QtQuick
import QtTest
import "../WindowModel.js" as WindowModel

TestCase {
    name: "Selection"

    readonly property var a: ({title: "a"})
    readonly property var b: ({title: "b"})
    readonly property var c: ({title: "c"})

    function test_emptyListSelectsNothing() {
        compare(WindowModel.selectionFor([], a, b), null);
    }

    function test_singleWindowIsSelectedWhateverWasChosen() {
        compare(WindowModel.selectionFor([a], null, null), a);
    }

    function test_chosenWindowWinsWhileListed() {
        compare(WindowModel.selectionFor([a, b, c], c, a), c);
    }

    function test_unlistedChoiceFallsBackToOrigin() {
        compare(WindowModel.selectionFor([a, b], c, b), b);
    }

    function test_unlistedChoiceAndOriginFallBackToFirst() {
        compare(WindowModel.selectionFor([b, c], a, a), b);
    }

    // Closing a window listed before the chosen one must not move the
    // selection onto its neighbour, as a stored index did.
    function test_closingAnEarlierWindowKeepsTheChoice() {
        compare(WindowModel.selectionFor([b, c], c, null), c);
    }
}
