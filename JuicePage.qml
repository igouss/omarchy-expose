import QtQuick
import QtQuick.Layouts

// Game-style feedback, one switch per effect.
SettingsPage {
    id: page
    readonly property var focusControls: [springToggle]
    categoryIndex: 7
    title: "Feel and feedback"

    SettingRow {
        dialog: page.dialog
        label: "Springy motion"
        description: "Moves overshoot and settle. Carousel cards stretch as they travel; the grid's lifted card pops."

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: springToggle
            view: page.view
            checked: view.controller.juiceSpring
            onToggled: function (checked) { view.controller.setSetting("juiceSpring", checked); }
        }
    }
}
