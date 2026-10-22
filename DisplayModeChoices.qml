import QtQuick
import "SettingsSchema.js" as SettingsSchema
import QtQuick.Layouts
import qs.Commons as Commons

RowLayout {
    id: displayModeChoices
    property var view: null
    Layout.fillWidth: true
    property string value: "mirrored"
    signal chosen(string nextValue)
    readonly property var options: SettingsSchema.options("multiMonitorMode")
    spacing: 0
    activeFocusOnTab: true

    function choose(index) {
        var next = Math.max(0, Math.min(displayModeChoices.options.length - 1, index));
        var value = String(displayModeChoices.options[next].value);
        if (value !== displayModeChoices.value)
            displayModeChoices.chosen(value);
    }

    Keys.onPressed: function (event) {
        if (view.controller.handleSettingsNavigation(event))
            return;
        var current = displayModeChoices.value === "per-monitor" ? 1 : 0;
        if (event.key === Qt.Key_Left)
            displayModeChoices.choose(current - 1);
        else if (event.key === Qt.Key_Right)
            displayModeChoices.choose(current + 1);
        else if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            displayModeChoices.choose(1 - current);
        else {
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    Repeater {
        model: displayModeChoices.options

        delegate: ThemedControl {
            id: displayModeChoice
            required property var modelData
            selected: String(modelData.value) === displayModeChoices.value
            focused: displayModeChoices.activeFocus && selected
            hovered: displayModeMouse.containsMouse
            pressed: displayModeMouse.pressed
            Layout.fillWidth: true
            Layout.preferredHeight: displayModeText.implicitHeight + Commons.Style.spacing.md * 2

            ColumnLayout {
                id: displayModeText
                anchors.fill: parent
                anchors.margins: Commons.Style.spacing.md
                spacing: Commons.Style.spacing.xs

                Text {
                    Layout.fillWidth: true
                    text: String(displayModeChoice.modelData.label)
                    textFormat: Text.PlainText
                    color: displayModeChoice.stateColor
                    font.family: Commons.Style.font.menuFamily
                    font.pixelSize: Commons.Style.font.body
                    font.bold: displayModeChoice.selected
                }

                Text {
                    Layout.fillWidth: true
                    text: String(displayModeChoice.modelData.description)
                    textFormat: Text.PlainText
                    color: Commons.Color.menu.text
                    opacity: 0.45
                    font.family: Commons.Style.font.menuFamily
                    font.pixelSize: Commons.Style.font.caption
                    wrapMode: Text.Wrap
                }
            }

            MouseArea {
                id: displayModeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    displayModeChoices.forceActiveFocus();
                    displayModeChoices.chosen(String(displayModeChoice.modelData.value));
                }
            }
        }
    }
}
