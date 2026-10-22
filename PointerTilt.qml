import QtQuick

// Pointer tilt: while `active` and the pointer is over `area`, two angles that
// raise the card's side under the pointer, easing back to flat when it leaves. Use
// `aroundY` on a Rotation about the y axis and `aroundX` on one about x.
Item {
    id: tilt

    required property MouseArea area
    property bool active: false
    readonly property real maxAngle: 7
    readonly property bool leaning: active && area.containsMouse

    // The side under the pointer rises toward the viewer; sinking it would
    // shrink that side out from under the pointer and end the hover.
    property real aroundY: leaning ? -(area.mouseX / Math.max(1, area.width) - 0.5) * 2 * maxAngle : 0
    property real aroundX: leaning ? (area.mouseY / Math.max(1, area.height) - 0.5) * 2 * maxAngle : 0

    Behavior on aroundY { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    Behavior on aroundX { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
}
