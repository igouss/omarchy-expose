import QtQuick
import QtQuick.Layouts

SettingsPage {
    id: page
    readonly property var focusControls: [hotCornerToggle, hotCornerPositionChoices, hotCornerAllDisplaysToggle, hotCornerDelaySlider]
    categoryIndex: 4
    title: "Activate from a corner"

    SettingRow {
        dialog: page.dialog
        label: "Enable hot corner"
        description: "Open or close Exposé by moving the pointer into the chosen corner."

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: hotCornerToggle
            view: page.view
            checked: view.controller.hotCornerEnabled
            onToggled: function (checked) { view.controller.setHotCornerEnabled(checked); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Corner"
        description: "Choose the corner that activates Exposé. Avoid using the same corner in another hot-corner plugin."
        enabled: view.controller.hotCornerEnabled

        SettingChoices {
            id: hotCornerPositionChoices
            view: page.view
            Layout.fillWidth: true
            value: view.controller.hotCornerPosition
            options: [
                { label: "Top left", value: "top-left" },
                { label: "Top right", value: "top-right" },
                { label: "Bottom left", value: "bottom-left" },
                { label: "Bottom right", value: "bottom-right" }
            ]
            onChosen: function (value) { view.controller.setHotCornerPosition(value); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Use on all displays"
        description: "When off, only the outermost display on the chosen side responds."
        enabled: view.controller.hotCornerEnabled

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: hotCornerAllDisplaysToggle
            view: page.view
            checked: view.controller.hotCornerAllDisplays
            onToggled: function (checked) { view.controller.setHotCornerAllDisplays(checked); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Activation delay"
        description: "How long the pointer must stay in the corner. Set to 0 for instant activation."
        enabled: view.controller.hotCornerEnabled

        SettingSlider {
            id: hotCornerDelaySlider
            view: page.view
            Layout.fillWidth: true
            from: 0
            to: 1000
            stepSize: 25
            value: view.controller.effectiveHotCornerDelay
            suffix: " ms"
            onEdited: function (value) { view.controller.hotCornerDelayPreview = value; }
            onCommitted: function (value) {
                view.controller.hotCornerDelayPreview = view.controller.setHotCornerDelay(value);
            }
        }
    }
}
