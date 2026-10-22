import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons

ColumnLayout {
    id: settingRow
    property var dialog: null
    default property alias controls: rowControls.data
    property string label: ""
    property string description: ""
    property bool stacked: dialog.narrow
    objectName: "settingRow"
    Layout.fillWidth: true
    spacing: Commons.Style.spacing.sm
    opacity: enabled ? 1 : 0.45

    SettingsDivider { Layout.fillWidth: true }

    GridLayout {
        Layout.fillWidth: true
        Layout.topMargin: Commons.Style.spacing.sm
        columns: settingRow.stacked ? 1 : 2
        columnSpacing: Commons.Style.spacing.md
        rowSpacing: Commons.Style.spacing.sm

        Text {
            Layout.fillWidth: true
            Layout.preferredWidth: settingRow.stacked ? -1 : Commons.Style.space(180)
            text: settingRow.label
            textFormat: Text.PlainText
            color: Commons.Color.menu.text
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.font.body
            wrapMode: Text.WordWrap
        }

        RowLayout {
            id: rowControls
            Layout.fillWidth: true
            Layout.preferredWidth: Commons.Style.space(320)
            spacing: 0
        }
    }

    Text {
        Layout.fillWidth: true
        text: settingRow.description
        textFormat: Text.PlainText
        color: Commons.Color.menu.text
        opacity: 0.65
        font.family: Commons.Style.font.menuFamily
        font.pixelSize: Commons.Style.font.caption
        wrapMode: Text.WordWrap
    }
}
