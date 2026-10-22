import QtQuick
import QtQuick.Layouts

SettingsPage {
    id: page
    readonly property var focusControls: [previewPlacementChoices, movePointerToggle]
    categoryIndex: 1
    title: "Quick Look and activation"

    SettingRow {
        dialog: page.dialog
        label: "Quick Look position"
        description: "When you press Space, enlarge the preview near its card or at the center of the display."

        SettingChoices {
            id: previewPlacementChoices
            view: page.view
            Layout.fillWidth: true
            value: view.controller.previewPlacement
            options: [
                { label: "In place", value: "in-place" },
                { label: "Centered", value: "centered" }
            ]
            onChosen: function (value) { view.controller.setPreviewPlacement(value); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Move pointer to window"
        description: "Move the pointer to the window you activate from the overview."

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: movePointerToggle
            view: page.view
            checked: view.controller.moveCursorToWindow
            onToggled: function (checked) { view.controller.setMoveCursorToWindow(checked); }
        }
    }
}
