import QtQuick
import QtTest
import "../CrtLayout.js" as CrtLayout
import "../GridLayout.js" as GridLayout

TestCase {
    name: "CrtLayout"

    function test_panesSplitTheWidthWithAGap() {
        let split = CrtLayout.panes(1000, 600, 20);
        compare(split.list.width, Math.round(1000 * CrtLayout.listFraction - 10));
        compare(split.monitor.x, split.list.width + 20);
        compare(split.monitor.x + split.monitor.width, 1000);
        compare(split.list.height, 600);
        compare(split.monitor.height, 600);
    }

    function test_noSpaceGivesEmptyPanes() {
        let split = CrtLayout.panes(0, 0, 20);
        compare(split.list.width, 0);
        compare(split.monitor.width, 0);
    }

    function test_rowsStackAndArrowsWalkThem() {
        compare(CrtLayout.rowRects(0, 30, 400).length, 0);
        let rows = CrtLayout.rowRects(3, 30, 400);
        compare(rows[2], { x: 0, y: 60, width: 400, height: 30 });
        compare(GridLayout.neighbourIndex(rows, 0, 0, 1), 1);
        compare(GridLayout.neighbourIndex(rows, 1, 0, -1), 0);
        compare(GridLayout.neighbourIndex(rows, 2, 0, 1), -1);
        compare(GridLayout.neighbourIndex(rows, 1, 1, 0), -1);
    }

    // Ten rows of 30 in a view of 120 (four rows).
    function test_aShortListNeverScrolls() {
        compare(CrtLayout.listOffset(2, 3, 30, 120, 0), 0);
        compare(CrtLayout.listOffset(2, 3, 30, 120, 50), 0);
    }

    function test_noSelectionKeepsTheOffsetInRange() {
        compare(CrtLayout.listOffset(-1, 10, 30, 120, 60), 60);
        compare(CrtLayout.listOffset(-1, 10, 30, 120, 500), 180);
        compare(CrtLayout.listOffset(-1, 0, 30, 120, 60), 0);
    }

    // Before the pane is laid out its height is zero; scrolling then would park
    // the selection at the top once the pane grows.
    function test_aViewWithNoHeightKeepsTheOffset() {
        compare(CrtLayout.listOffset(4, 45, 30, 0, 0), 0);
        compare(CrtLayout.listOffset(4, 45, 30, 0, 60), 60);
    }

    function test_aSelectionInViewDoesNotMoveTheList() {
        compare(CrtLayout.listOffset(3, 10, 30, 120, 30), 30);
    }

    function test_movingDownScrollsToShowTheNextRow() {
        // Row 4 spans 120-150; with a row of context below, the view ends at 180.
        compare(CrtLayout.listOffset(4, 10, 30, 120, 0), 60);
    }

    function test_movingUpScrollsToShowThePreviousRow() {
        compare(CrtLayout.listOffset(3, 10, 30, 120, 150), 60);
    }

    function test_theEndsClampTheContext() {
        compare(CrtLayout.listOffset(0, 10, 30, 120, 90), 0);
        compare(CrtLayout.listOffset(9, 10, 30, 120, 0), 180);
    }

    // A view under three rows tall has no room for context; the row itself still
    // shows. Exactly three rows fit the row and one either side.
    function test_aTinyViewShowsJustTheSelection() {
        compare(CrtLayout.listOffset(5, 10, 30, 50, 0), 130);
        compare(CrtLayout.listOffset(5, 10, 30, 90, 0), 120);
    }

    function test_rowsTypeInOneAfterAnother() {
        compare(CrtLayout.typed(0, 1, 0), 0);
        compare(CrtLayout.typed(0, 1, CrtLayout.typeSpan), 1);
        compare(CrtLayout.typed(0, 3, 0.25), 0.5);
        compare(CrtLayout.typed(2, 3, 0.5), 0);
        compare(CrtLayout.typed(2, 3, 0.75), 0.5);
        compare(CrtLayout.typed(2, 3, 1), 1);
        verify(CrtLayout.typed(1, 3, 0.5) > CrtLayout.typed(2, 3, 0.5), "an earlier row is further along");
    }

    function test_columnsCutAndPad() {
        compare(CrtLayout.column("", 3), "   ");
        compare(CrtLayout.column("ab", 3), "ab ");
        compare(CrtLayout.column("abc", 3), "abc");
        compare(CrtLayout.column("abcd", 3), "ab…");
        compare(CrtLayout.column("abcd", 1), "a");
    }

    function test_appsGoByTheirLastName() {
        compare(CrtLayout.appName("com.mitchellh.ghostty"), "ghostty");
        compare(CrtLayout.appName("foot"), "foot");
        compare(CrtLayout.appName(""), "-");
        compare(CrtLayout.appName("org.gnome."), "gnome");
    }

    function test_rowsLineUpInColumns() {
        compare(CrtLayout.row(3, "1", "ghostty", "Shell"), "03 ws:1   ghostty      Shell");
        compare(CrtLayout.row(12, "web", "com.mitchellh.ghostty", "x").length,
            CrtLayout.row(1, "1", "a", "x").length);
    }
}
