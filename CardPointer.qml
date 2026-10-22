import QtQuick

// The pointer on one window's card. Middle click closes the window. Where the
// cards never move under the pointer (`hoverSelects`), hover selects and a
// click opens; where selecting moves the cards, a click selects and a click
// on the selection opens. Fill the card with it; disabled while Settings or
// another window's Quick Look is up.
MouseArea {
    id: pointer

    required property var controller
    required property var toplevel
    required property bool acceptsKeyboard
    required property bool selected
    required property bool previewed
    property bool hoverSelects: false
    // Hover as the card shows it: cleared at once when the pointer is disabled.
    property bool hovering: false

    anchors.fill: parent
    enabled: !controller.settingsOpen && (!controller.previewToplevel || previewed)
    hoverEnabled: hoverSelects || controller.juiceTilt
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    onEnabledChanged: {
        if (enabled)
            return;
        pointer.hovering = false;
        if (pointer.controller.hoveredToplevel === pointer.toplevel)
            pointer.controller.hoveredToplevel = null;
    }
    onEntered: {
        pointer.hovering = true;
        if (pointer.hoverSelects && pointer.acceptsKeyboard) {
            pointer.controller.hoveredToplevel = pointer.toplevel;
            pointer.controller.selectedToplevel = pointer.toplevel;
        }
    }
    onExited: {
        pointer.hovering = false;
        if (pointer.acceptsKeyboard && pointer.controller.hoveredToplevel === pointer.toplevel)
            pointer.controller.hoveredToplevel = null;
    }
    onClicked: function (mouse) {
        if (mouse.button === Qt.MiddleButton)
            pointer.controller.requestClose(pointer.toplevel);
        else if (pointer.hoverSelects || pointer.selected)
            pointer.controller.activate(pointer.toplevel);
        else if (pointer.acceptsKeyboard)
            pointer.controller.selectedToplevel = pointer.toplevel;
    }
}
