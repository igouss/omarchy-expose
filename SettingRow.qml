import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
    id: settingRow
    property var dialog: null
    default property alias controls: rowControls.data
    property string label: ""
    property string description: ""
    property bool stacked: dialog.narrow
    objectName: "settingRow"
    Layout.fillWidth: true
    spacing: Style.spacing.sm
    opacity: enabled ? 1 : 0.45

    SettingsDivider { Layout.fillWidth: true }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: Style.spacing.sm
        columns: settingRow.stacked ? 1 : 2
        columnSpacing: Style.spacing.md
        rowSpacing: Style.spacing.sm

        Text {
            Layout.fillWidth: true
            Layout.preferredWidth: settingRow.stacked ? -1 : Style.space(180)
            text: settingRow.label
            textFormat: Text.PlainText
            color: Color.menu.text
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
        }

        RowLayout {
            id: rowControls
            Layout.fillWidth: true
            Layout.preferredWidth: Style.space(320)
            spacing: 0
        }
    }

    Text {
        Layout.fillWidth: true
        text: settingRow.description
        textFormat: Text.PlainText
        color: Color.menu.text
        opacity: 0.65
        font.family: Style.font.menuFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
    }
}
