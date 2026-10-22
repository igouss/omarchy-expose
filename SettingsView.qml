import QtQuick
import "SettingsSchema.js" as SettingsSchema
import QtQuick.Layouts
import qs.Commons as Commons
import qs.Ui as Ui

Item {
    id: settingsView

    required property var controller
    required property var hostWindow
    readonly property var categories: SettingsSchema.categories
    readonly property int navigationColumns: settingsDialog.narrow ? (settingsDialog.width < Commons.Style.space(540) ? 2 : 3) : 1
    readonly property int navigationRows: Math.ceil(categories.length / navigationColumns)
    readonly property var slideDirectionOptions: [
        { label: "Left", value: "left" },
        { label: "Right", value: "right" },
        { label: "Up", value: "up" },
        { label: "Down", value: "down" }
    ]

    function revealSettingsItem(item) {
        for (let parent = item.parent; parent; parent = parent.parent) {
            if (parent instanceof Flickable) {
                parent.reveal(item);
                return;
            }
        }
    }

    anchors.fill: parent

    function availableFocusItems(candidates) {
        var items = [];
        for (let index = 0; index < candidates.length; index++) {
            let candidate = candidates[index];
            if (candidate && candidate.visible && candidate.enabled)
                items.push(candidate);
        }
        return items;
    }

    function settingsFocusItems() {
        var categoryButton = settingsCategoryRepeater.itemAt(settingsView.controller.settingsCategoryIndex);
        var controls = [
            lookPage.focusControls,
            appearancePage.focusControls,
            windowsPage.focusControls,
            windowLabelsPage.focusControls,
            workspacesPage.focusControls,
            hotCornerPage.focusControls,
            motionPage.focusControls
        ];
        return settingsView.availableFocusItems([categoryButton].concat(controls[settingsView.controller.settingsCategoryIndex] || []));
    }

    function footerConfirmationFocusItems() {
        return settingsView.availableFocusItems(footerHideConfirmation.focusControls);
    }

    function moveFocus(items, forward, forwardFallbackIndex, wrap) {
        if (!items.length)
            return;
        var focusedIndex = -1;
        for (let index = 0; index < items.length; index++) {
            if (items[index].activeFocus) {
                focusedIndex = index;
                break;
            }
        }
        var nextIndex;
        if (focusedIndex < 0)
            nextIndex = forward ? Math.min(forwardFallbackIndex, items.length - 1) : items.length - 1;
        else if (wrap)
            nextIndex = (focusedIndex + (forward ? 1 : items.length - 1)) % items.length;
        else
            nextIndex = focusedIndex + (forward ? 1 : -1);
        if (nextIndex < 0 || nextIndex >= items.length)
            return;
        settingsView.controller.focusSettingsItem(items[nextIndex]);
        settingsView.revealSettingsItem(items[nextIndex]);
    }

    function holdsFocus() {
        var item = settingsView.Window.activeFocusItem;
        if (!item || !item.visible)
            return false;
        for (; item; item = item.parent)
            if (item === settingsView)
                return true;
        return false;
    }

    function focusSettingsCategory() {
        var categoryButton = settingsCategoryRepeater.itemAt(settingsView.controller.settingsCategoryIndex);
        if (categoryButton)
            categoryButton.forceActiveFocus();
    }

    function moveSettingsFocus(forward, wrap) {
        settingsView.moveFocus(settingsView.settingsFocusItems(), forward, 1, wrap);
    }

    function focusFirstSettingsControl() {
        var items = settingsView.settingsFocusItems();
        if (items.length > 1) {
            settingsView.controller.focusSettingsItem(items[1]);
            settingsView.revealSettingsItem(items[1]);
        }
    }

    function moveFooterConfirmationFocus(forward, wrap) {
        settingsView.moveFocus(settingsView.footerConfirmationFocusItems(), forward, 0, wrap);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: settingsView.controller.closeSettings()
    }

    Ui.BorderSurface {
        id: settingsDialog
        readonly property bool narrow: width < Commons.Style.space(760)
        anchors.centerIn: parent
        width: Math.min(Commons.Style.space(920), parent.width - Commons.Style.space(80))
        height: Math.min(Commons.Style.space(narrow ? 720 : 640), parent.height - Commons.Style.space(80))
        radius: Commons.Style.cornerRadius
        color: Commons.Color.menu.background
        borderSpec: Commons.Border.surfaceSpec("menu", "border", Commons.Color.foreground, Commons.Style.normalBorderWidth)
        enabled: !settingsView.controller.footerHideConfirmationOpen

        MouseArea {
            anchors.fill: parent
            onClicked: function (mouse) { mouse.accepted = true; }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Commons.Style.space(66)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Commons.Style.space(24)
                    anchors.rightMargin: Commons.Style.space(24)
                    spacing: Commons.Style.spacing.lg

                    Text {
                        text: "Exposé settings"
                        textFormat: Text.PlainText
                        color: Commons.Color.menu.text
                        font.family: Commons.Style.font.menuFamily
                        font.pixelSize: Commons.Style.font.heading
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: !settingsDialog.narrow
                        text: "1–" + settingsView.categories.length + " section   ↑↓ move   ←→ adjust   Esc close"
                        textFormat: Text.PlainText
                        color: Commons.Color.menu.text
                        opacity: 0.5
                        font.family: Commons.Style.font.menuFamily
                        font.pixelSize: Commons.Style.font.caption
                    }
                }
            }

            SettingsDivider { Layout.fillWidth: true }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: settingsDialog.narrow ? 1 : 2
                columnSpacing: 0
                rowSpacing: 0

                Item {
                    Layout.fillWidth: settingsDialog.narrow
                    Layout.fillHeight: !settingsDialog.narrow
                    Layout.preferredWidth: settingsDialog.narrow ? 0 : Commons.Style.space(218)
                    Layout.preferredHeight: settingsDialog.narrow ? Commons.Style.space(52) * settingsView.navigationRows : 0

                    GridLayout {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        columns: settingsView.navigationColumns
                        columnSpacing: 0
                        rowSpacing: 0

                        Repeater {
                            id: settingsCategoryRepeater
                            model: settingsView.categories

                            delegate: SettingsCategoryButton {
                                view: settingsView
                                required property int index
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: Commons.Style.space(settingsDialog.narrow ? 52 : 48)
                                categoryIndex: index
                                categoryCount: settingsCategoryRepeater.count
                                label: String(modelData)
                                selected: settingsView.controller.settingsCategoryIndex === index
                                horizontal: settingsDialog.narrow
                                navigationColumns: settingsView.navigationColumns
                                onChosen: function (nextIndex) {
                                    settingsView.controller.settingsCategoryIndex = nextIndex;
                                    var nextButton = settingsCategoryRepeater.itemAt(nextIndex);
                                    if (nextButton)
                                        nextButton.forceActiveFocus();
                                }
                                onEntered: settingsView.hostWindow.focusFirstSettingsControl()
                            }
                        }
                    }

                    ThemeDivider {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        vertical: !settingsDialog.narrow
                        width: vertical ? implicitWidth : parent.width
                        height: vertical ? parent.height : implicitHeight
                    }
                }

                Item {
                    id: settingsCategoryContent
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    LookPage {
                        id: lookPage
                        view: settingsView
                        dialog: settingsDialog
                    }

                    AppearancePage {
                        id: appearancePage
                        view: settingsView
                        dialog: settingsDialog
                    }

                    WindowsPage {
                        id: windowsPage
                        view: settingsView
                        dialog: settingsDialog
                    }

                    WindowLabelsPage {
                        id: windowLabelsPage
                        view: settingsView
                        dialog: settingsDialog
                    }

                    WorkspacesPage {
                        id: workspacesPage
                        view: settingsView
                        dialog: settingsDialog
                    }

                    HotCornerPage {
                        id: hotCornerPage
                        view: settingsView
                        dialog: settingsDialog
                    }

                    MotionPage {
                        id: motionPage
                        view: settingsView
                        dialog: settingsDialog
                    }
                }
            }

            SettingsDivider { Layout.fillWidth: true }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Commons.Style.space(44)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Commons.Style.space(24)
                    anchors.rightMargin: Commons.Style.space(24)
                    spacing: Commons.Style.spacing.lg

                    Text {
                        text: "Changes save immediately"
                        textFormat: Text.PlainText
                        color: Commons.Color.menu.text
                        opacity: 0.45
                        font.family: Commons.Style.font.menuFamily
                        font.pixelSize: Commons.Style.font.caption
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: !settingsDialog.narrow
                        text: "1–" + settingsView.categories.length + " category   Tab controls"
                        textFormat: Text.PlainText
                        color: Commons.Color.menu.text
                        opacity: 0.45
                        font.family: Commons.Style.font.menuFamily
                        font.pixelSize: Commons.Style.font.caption
                    }
                }
            }
        }
    }
    FooterHideConfirmation {
        id: footerHideConfirmation
        view: settingsView
        bottomTextToggle: appearancePage.bottomTextToggleItem
    }
}
