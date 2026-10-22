import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons

ThemedControl {
    id: categoryButton
    property var view: null
    property int categoryIndex: 0
    property int categoryCount: 1
    property string label: ""
    property bool horizontal: false
    property int navigationColumns: 1
    focused: activeFocus
    pressed: categoryMouse.pressed
    signal chosen(int nextIndex)
    implicitWidth: Commons.Style.space(horizontal ? 140 : 200)
    implicitHeight: Commons.Style.space(horizontal ? 52 : 48)
    activeFocusOnTab: selected

    signal entered()

    function choose(nextIndex) {
        categoryButton.chosen(Math.max(0, Math.min(categoryButton.categoryCount - 1, nextIndex)));
    }

    // Navigate the sidebar or wrapped category grid. Enter/Space moves
    // into the page; Down from the grid’s last row also enters it.
    Keys.onPressed: function (event) {
        if (view.controller.handleSettingsTab(event))
            return;
        var previousKey = categoryButton.horizontal ? Qt.Key_Left : Qt.Key_Up;
        var nextKey = categoryButton.horizontal ? Qt.Key_Right : Qt.Key_Down;
        var enterKey = categoryButton.horizontal ? Qt.Key_Down : Qt.Key_Right;
        if (event.key === previousKey)
            categoryButton.choose(categoryButton.categoryIndex - 1);
        else if (event.key === nextKey)
            categoryButton.choose(categoryButton.categoryIndex + 1);
        else if (event.key === Qt.Key_Home)
            categoryButton.choose(0);
        else if (event.key === Qt.Key_End)
            categoryButton.choose(categoryButton.categoryCount - 1);
        else if (categoryButton.horizontal && event.key === Qt.Key_Up)
            categoryButton.choose(Math.max(0, categoryButton.categoryIndex - categoryButton.navigationColumns));
        else if (categoryButton.horizontal && event.key === Qt.Key_Down
                && categoryButton.categoryIndex + categoryButton.navigationColumns < categoryButton.categoryCount)
            categoryButton.choose(categoryButton.categoryIndex + categoryButton.navigationColumns);
        else if (event.key === enterKey
                || event.key === Qt.Key_Space
                || event.key === Qt.Key_Return
                || event.key === Qt.Key_Enter)
            categoryButton.entered();
        else {
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Commons.Style.space(categoryButton.horizontal ? 8 : 18)
        anchors.rightMargin: Commons.Style.space(categoryButton.horizontal ? 8 : 18)
        spacing: Commons.Style.spacing.md

        Text {
            Layout.preferredWidth: Commons.Style.space(18)
            text: String(categoryButton.categoryIndex + 1)
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            color: categoryButton.stateColor
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.font.caption
            font.bold: categoryButton.selected
        }

        Text {
            Layout.fillWidth: true
            text: categoryButton.label
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignLeft
            color: categoryButton.stateColor
            font.family: Commons.Style.font.menuFamily
            font.pixelSize: Commons.Style.font.bodySmall
            font.bold: categoryButton.selected
            elide: Text.ElideRight
        }

    }

    MouseArea {
        id: categoryMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: categoryButton.hovered = true
        onExited: categoryButton.hovered = false
        onPressed: categoryButton.forceActiveFocus()
        onClicked: categoryButton.choose(categoryButton.categoryIndex)
    }
}
