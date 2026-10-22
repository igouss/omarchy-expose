import QtQuick

// What every look provides to the overview canvas. A look fills the overview
// area, draws screenWindow.screenToplevels however it likes, and reports one
// rect per window in that order: arrow keys move between the nearest rects.
Item {
    required property var overview
    required property var screenWindow
    property var windowLayout: []
}
