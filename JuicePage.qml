import QtQuick
import QtQuick.Layouts

// Game-style feedback, one switch per effect.
SettingsPage {
    id: page
    readonly property var focusControls: [springToggle, edgeBumpToggle]
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

    SettingRow {
        dialog: page.dialog
        label: "Edge bump"
        description: "An arrow with no window that way shakes the selection instead of doing nothing; the carousel rubber-bands."

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: edgeBumpToggle
            view: page.view
            checked: view.controller.juiceEdgeBump
            onToggled: function (checked) { view.controller.setSetting("juiceEdgeBump", checked); }
        }
    }
}
