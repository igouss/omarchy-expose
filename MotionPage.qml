import QtQuick
import "SettingsSchema.js" as SettingsSchema
import QtQuick.Layouts

SettingsPage {
    id: page
    readonly property var focusControls: [motionAnimateButton, animationStyleChoices, animationSameSpeedToggle, slideDirectionChoices, slideDirectionInChoices, slideDirectionOutChoices, animationSpeedSlider, animationInSlider, animationOutSlider]
    categoryIndex: 6
    title: "Opening and closing"

    DialogButton {
        id: motionAnimateButton
        view: page.view
        Layout.alignment: Qt.AlignRight
        label: "Preview animation"
        onClicked: view.controller.previewAnimation()
    }

    SettingRow {
        dialog: page.dialog
        label: "Animation style"
        description: "Choose how the overview opens and closes. Each style remembers its own timing."

        SettingChoices {
            id: animationStyleChoices
            view: page.view
            Layout.fillWidth: true
            value: view.controller.animationStyle
            options: SettingsSchema.options("animationStyle")
            onChosen: function (value) {
                view.controller.clearAnimationTimingPreview();
                view.controller.setSetting("animationStyle", value);
            }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Same opening and closing"
        description: "Use the same duration for both transitions. For Slide, this also links their directions."

        Item { Layout.fillWidth: true }

        SettingToggle {
            id: animationSameSpeedToggle
            view: page.view
            checked: !view.controller.animationTimingFor(view.controller.animationStyle).separate
            onToggled: function (checked) {
                view.controller.clearAnimationTimingPreview();
                view.controller.setAnimationTimingSeparate(view.controller.animationStyle, !checked);
            }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Slide edge"
        description: "The edge the overview slides in from and out to."
        visible: view.controller.animationStyle === "slide" && !view.controller.animationTimingFor(view.controller.animationStyle).separate

        SettingChoices {
            id: slideDirectionChoices
            view: page.view
            Layout.fillWidth: true
            value: String(view.controller.slideDirection["in"])
            options: view.slideDirectionOptions
            onChosen: function (value) { view.controller.setSlideDirection(value); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Slide in from"
        description: "The edge the overview enters from when opening."
        visible: view.controller.animationStyle === "slide" && view.controller.animationTimingFor(view.controller.animationStyle).separate

        SettingChoices {
            id: slideDirectionInChoices
            view: page.view
            Layout.fillWidth: true
            value: String(view.controller.slideDirection["in"])
            options: view.slideDirectionOptions
            onChosen: function (value) { view.controller.setSlideDirectionIn(value); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Slide out to"
        description: "The edge the overview leaves through when closing."
        visible: view.controller.animationStyle === "slide" && view.controller.animationTimingFor(view.controller.animationStyle).separate

        SettingChoices {
            id: slideDirectionOutChoices
            view: page.view
            Layout.fillWidth: true
            value: String(view.controller.slideDirection["out"])
            options: view.slideDirectionOptions
            onChosen: function (value) { view.controller.setSlideDirectionOut(value); }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Duration"
        description: "Time for each transition. Lower values are faster; higher values are slower."
        visible: !view.controller.animationTimingFor(view.controller.animationStyle).separate

        SettingSlider {
            id: animationSpeedSlider
            view: page.view
            Layout.fillWidth: true
            from: 100
            to: 800
            stepSize: 10
            value: view.controller.animationInDurationFor(view.controller.animationStyle)
            suffix: " ms"
            onEdited: function (value) {
                view.controller.animationDurationPreviewStyle = view.controller.animationStyle;
                view.controller.animationInDurationPreview = value;
                view.controller.animationOutDurationPreview = value;
            }
            onCommitted: function (value) {
                var next = view.controller.setAnimationDuration(view.controller.animationStyle, value);
                view.controller.animationDurationPreviewStyle = view.controller.animationStyle;
                view.controller.animationInDurationPreview = next;
                view.controller.animationOutDurationPreview = next;
            }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Opening duration"
        description: "Time taken to open the overview. Lower values are faster."
        visible: view.controller.animationTimingFor(view.controller.animationStyle).separate

        SettingSlider {
            id: animationInSlider
            view: page.view
            Layout.fillWidth: true
            from: 100
            to: 800
            stepSize: 10
            value: view.controller.animationInDurationFor(view.controller.animationStyle)
            suffix: " ms"
            onEdited: function (value) {
                view.controller.animationDurationPreviewStyle = view.controller.animationStyle;
                view.controller.animationInDurationPreview = value;
            }
            onCommitted: function (value) {
                var next = view.controller.setAnimationDurationIn(view.controller.animationStyle, value);
                view.controller.animationDurationPreviewStyle = view.controller.animationStyle;
                view.controller.animationInDurationPreview = next;
            }
        }
    }

    SettingRow {
        dialog: page.dialog
        label: "Closing duration"
        description: "Time taken to close the overview. Lower values are faster."
        visible: view.controller.animationTimingFor(view.controller.animationStyle).separate

        SettingSlider {
            id: animationOutSlider
            view: page.view
            Layout.fillWidth: true
            from: 100
            to: 800
            stepSize: 10
            value: view.controller.animationOutDurationFor(view.controller.animationStyle)
            suffix: " ms"
            onEdited: function (value) {
                view.controller.animationDurationPreviewStyle = view.controller.animationStyle;
                view.controller.animationOutDurationPreview = value;
            }
            onCommitted: function (value) {
                var next = view.controller.setAnimationDurationOut(view.controller.animationStyle, value);
                view.controller.animationDurationPreviewStyle = view.controller.animationStyle;
                view.controller.animationOutDurationPreview = next;
            }
        }
    }
}
