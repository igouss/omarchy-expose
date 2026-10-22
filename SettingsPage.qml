import QtQuick
import QtQuick.Layouts
import qs.Commons

Flickable {
    id: settingsPage
    property var view: null
    property var dialog: null
    default property alias settings: pageColumn.data
    property int categoryIndex: 0
    property string title: ""
    anchors.fill: parent
    anchors.margins: Style.space(dialog.narrow ? 20 : 28)
    visible: view.controller.settingsCategoryIndex === categoryIndex
    enabled: visible
    clip: true
    contentWidth: width
    contentHeight: pageColumn.implicitHeight
    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds

    function reveal(item) {
        var row = item;
        while (row.parent && row.parent !== settingsPage.contentItem && row.objectName !== "settingRow")
            row = row.parent;
        var top = row.mapToItem(settingsPage.contentItem, 0, 0).y;
        var bottom = top + row.height;
        if (top < contentY || row.height > height)
            contentY = Math.max(0, top);
        else if (bottom > contentY + height)
            contentY = Math.min(Math.max(0, contentHeight - height), bottom - height);
    }

    Rectangle {
        parent: settingsPage
        anchors.right: parent.right
        width: Style.space(2)
        height: settingsPage.height * settingsPage.visibleArea.heightRatio
        y: settingsPage.height * settingsPage.visibleArea.yPosition
        color: Color.menu.text
        opacity: 0.35
        visible: settingsPage.contentHeight > settingsPage.height
    }

    ColumnLayout {
        id: pageColumn
        width: settingsPage.width - Style.spacing.md
        spacing: Style.spacing.lg

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacing.xs

            Text {
                Layout.fillWidth: true
                text: view.categories[settingsPage.categoryIndex]
                textFormat: Text.PlainText
                color: Color.accent
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.capitalization: Font.AllUppercase
            }

            Text {
                Layout.fillWidth: true
                text: settingsPage.title
                textFormat: Text.PlainText
                color: Color.menu.text
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.heading
                font.bold: true
                wrapMode: Text.WordWrap
            }
        }
    }
}
