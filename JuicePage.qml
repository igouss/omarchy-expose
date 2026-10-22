import QtQuick
import QtQuick.Layouts

// Game-style feedback, one switch per effect.
SettingsPage {
    id: page
    readonly property var focusControls: [springToggle, edgeBumpToggle, punchToggle, pulseToggle]
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

    SettingRow {
        dialog: page.dialog
        label: "Activation punch"
        description: "The window you open flashes, jumps toward you, and throws sparks and the overview closes about 0.2 s later. Off, windows open at once."

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: punchToggle
            view: page.view
            checked: view.controller.juicePunch
            onToggled: function (checked) { view.controller.setSetting("juicePunch", checked); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Selection pulse"
        description: "The selection's glow breathes slowly. Applies to the carousel and to the grid's Lift highlight."

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: pulseToggle
            view: page.view
            checked: view.controller.juicePulse
            onToggled: function (checked) { view.controller.setSetting("juicePulse", checked); }
        }
    }
}
