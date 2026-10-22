import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "WindowModel.js" as WindowModel
import qs.Commons as Commons
import qs.Ui as Ui

Ui.BorderSurface {
    id: card

    required property var modelData
    required property var controller
    required property var screenToplevels
    required property bool acceptsKeyboard
    required property var windowLayout
    required property real layoutAreaWidth
    required property real layoutAreaHeight
    // Position in the filtered list; -1 hides the card.
    readonly property int slot: card.screenToplevels.indexOf(modelData)
    readonly property bool inLayout: slot >= 0
    property bool hovered: false
    readonly property bool selected: card.acceptsKeyboard && inLayout && modelData === card.controller.selection
    // The window the overview was opened from; the overlay holds focus while open.
    readonly property bool focusedWindow: modelData === card.controller.originToplevel
    readonly property bool previewed: card.acceptsKeyboard && inLayout && modelData === card.controller.previewToplevel
    readonly property bool exitingPreview: card.acceptsKeyboard && inLayout && modelData === card.controller.previewExitToplevel
    // Each footer style is one Component below, keyed by the setting's value.
    // Only "integrated" (Rail) frames the whole card; the others are frameless.
    readonly property string footerStyle: card.controller.windowFooterStyle
    readonly property bool railFooter: card.footerStyle === "integrated"
    readonly property bool overlaidFooter: card.footerStyle === "overlay"
    readonly property string windowTitle: String(modelData.title || WindowModel.appIdFor(modelData) || "Untitled window")
    readonly property string applicationName: WindowModel.appIdFor(modelData) || "Application"
    readonly property string workspaceName: card.controller.workspaceName(modelData)
    readonly property string iconSource: card.controller.iconFor(modelData)
    // Lift marks only the selection, which is what Enter opens; the window you
    // came from gets a dot instead of sharing the active border.
    readonly property bool liftSelection: card.controller.selectionStyle === "lift"
    readonly property bool lifted: liftSelection && selected && !previewed
    readonly property bool outlined: liftSelection ? selected : (hovered || selected || focusedWindow)
    readonly property var outlineSpec: outlined
        ? (liftSelection ? liftRingSpec : controller.windowBorders.activeSpec)
        : controller.windowBorders.inactiveSpec
    readonly property var liftRingSpec: {
        var active = controller.windowBorders.activeSpec;
        var ring = Commons.Border.flat(active.color, Math.max(3, controller.windowBorders.snapshot.width + 1));
        ring.gradient = active.gradient;
        return ring;
    }
    readonly property color currentColor: Commons.Style.selectedStateColor(Commons.Color.menu.text, Commons.Color.accent)
    // An excluded card keeps its last rectangle, so it neither
    // animates toward the origin nor flies back in from it.
    readonly property var packedRectSource: inLayout ? card.windowLayout[slot] : null
    property var packedRect: Qt.rect(0, 0, 1, 1)
    readonly property var previewRect: card.controller.previewRectFor(modelData, packedRect, card.layoutAreaWidth, card.layoutAreaHeight, Commons.Style.spacing.sm, card.controller.windowFooterHeight)
    readonly property var layoutRect: previewed ? previewRect : packedRect

    onPackedRectSourceChanged: {
        if (packedRectSource)
            packedRect = packedRectSource;

    }
    Component.onCompleted: {
        if (packedRectSource)
            packedRect = packedRectSource;

    }
    visible: inLayout
    transform: Translate { id: bumpShift }
    x: layoutRect.x
    y: layoutRect.y
    width: layoutRect.width
    height: layoutRect.height
    z: previewed ? 11 : (exitingPreview ? 10 : (lifted ? 1 : 0))
    scale: (lifted ? 1.04 : 1) * (1 + punch.zoom * 0.1)
    radius: card.railFooter ? Commons.Style.cornerRadius : 0
    color: card.railFooter ? Commons.Color.menu.background : "transparent"
    borderSpec: card.railFooter ? outlineSpec : Commons.Border.none()
    opacity: card.controller.previewToplevel
        ? (previewed ? 1 : 0.28)
        : (liftSelection && !selected ? 0.72 : 1)

    MouseArea {
        anchors.fill: parent
        enabled: !card.controller.settingsOpen && (!card.controller.previewToplevel || card.previewed)
        hoverEnabled: true
        onEnabledChanged: {
            if (!enabled) {
                card.hovered = false;
                if (card.controller.hoveredToplevel === card.modelData)
                    card.controller.hoveredToplevel = null;

            }
        }
        onEntered: {
            card.hovered = true;
            if (card.acceptsKeyboard) {
                card.controller.hoveredToplevel = card.modelData;
                card.controller.selectedToplevel = card.modelData;
            }
        }
        onExited: {
            card.hovered = false;
            if (card.acceptsKeyboard && card.controller.hoveredToplevel === card.modelData)
                card.controller.hoveredToplevel = null;

        }
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton)
                card.controller.requestClose(card.modelData);
            else
                card.controller.activate(card.modelData);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Commons.Style.spacing.sm
        spacing: card.overlaidFooter ? 0 : Commons.Style.spacing.sm

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: previewFrame
                anchors.margins: -Commons.Style.space(4)
                visible: card.liftSelection
                radius: previewFrame.radius + Commons.Style.space(4)
                color: Commons.Color.accent
                opacity: card.lifted ? 0.85 * card.controller.selectionBreath : 0
                layer.enabled: visible
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1
                    blurMax: 48
                    autoPaddingEnabled: true
                }

                Behavior on opacity {
                    enabled: card.controller.motionSettled

                    NumberAnimation {
                        duration: card.controller.previewFadeDuration
                    }

                }

            }

            WindowThumbnail {
                id: previewFrame

                readonly property real windowAspectRatio: card.controller.aspectRatioFor(card.modelData)

                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height * windowAspectRatio)
                height: Math.min(parent.height, parent.width / windowAspectRatio)
                radius: Math.max(0, Commons.Style.cornerRadius - Commons.Style.spacing.xs)
                toplevel: card.modelData
                live: card.controller.opened && card.inLayout

                Rectangle {
                    anchors.fill: parent
                    color: "white"
                    opacity: punch.flash
                }

                Loader {
                    anchors.fill: parent
                    active: card.overlaidFooter
                    sourceComponent: overlayFooter
                }
            }

            Ui.BorderSurface {
                anchors.fill: previewFrame
                visible: !card.railFooter
                z: 5
                radius: previewFrame.radius
                color: "transparent"
                borderSpec: card.outlineSpec
            }

            Rectangle {
                anchors.top: previewFrame.top
                anchors.right: previewFrame.right
                anchors.margins: Commons.Style.spacing.sm
                z: 6
                visible: card.liftSelection && card.focusedWindow
                width: Commons.Style.space(12)
                height: width
                radius: width / 2
                color: card.currentColor
                border.color: Commons.Color.menu.background
                border.width: Commons.Style.space(2)
            }

        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Commons.Style.space(40)
            visible: !card.overlaidFooter

            Loader {
                anchors.fill: parent
                sourceComponent: ({ floating: floatingFooter, integrated: integratedFooter, centered: centeredFooter })[card.footerStyle] || null
            }

        }

    }

    JuicePunch {
        id: punch
        anchors.fill: parent
        z: 20
        controller: card.controller
        toplevel: card.modelData
    }

    // Edge bump: the selection shakes along the arrow that found nothing.
    Connections {
        target: card.controller
        function onEdgeBumped(dx, dy) {
            if (!card.selected)
                return;
            bumpShake.dx = dx;
            bumpShake.dy = dy;
            bumpShake.restart();
        }
    }

    SequentialAnimation {
        id: bumpShake
        property int dx: 0
        property int dy: 0
        readonly property real reach: Commons.Style.space(14)
        ParallelAnimation {
            NumberAnimation { target: bumpShift; property: "x"; to: bumpShake.dx * bumpShake.reach; duration: 60; easing.type: Easing.OutQuad }
            NumberAnimation { target: bumpShift; property: "y"; to: bumpShake.dy * bumpShake.reach; duration: 60; easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: bumpShift; property: "x"; to: 0; duration: 320; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.3 }
            NumberAnimation { target: bumpShift; property: "y"; to: 0; duration: 320; easing.type: Easing.OutElastic; easing.amplitude: 1; easing.period: 0.3 }
        }
    }

    // Shared footer building blocks; each footer style overrides only what differs.
    component CardText: Text {
        textFormat: Text.PlainText
        color: Commons.Color.menu.text
        font.family: Commons.Style.font.menuFamily
        font.pixelSize: Commons.Style.font.body
    }

    component FooterTitle: CardText {
        text: card.windowTitle
        font.bold: card.selected
        elide: Text.ElideRight
    }

    component FooterIcon: Image {
        property int iconSize: 24
        Layout.preferredWidth: Commons.Style.space(iconSize)
        Layout.preferredHeight: Commons.Style.space(iconSize)
        source: card.iconSource
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }

    component WorkspaceColumn: ColumnLayout {
        spacing: 0

        CardText {
            Layout.alignment: Qt.AlignRight
            text: card.workspaceName
            color: card.focusedWindow ? card.currentColor : Commons.Color.menu.text
            font.pixelSize: Commons.Style.font.heading
            font.bold: true
        }

        CardText {
            Layout.alignment: Qt.AlignRight
            text: "Workspace"
            opacity: 0.55
            font.pixelSize: Commons.Style.font.caption
        }
    }

    // Only the configured footer style is instantiated per card.
    Component {
        id: overlayFooter

        Item {
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.min(parent.height * 0.45, Commons.Style.space(84))

                gradient: Gradient {
                    orientation: Gradient.Vertical

                    GradientStop {
                        position: 0
                        color: "transparent"
                    }

                    GradientStop {
                        position: 1
                        color: Commons.Color.menu.background
                    }
                }
            }

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Commons.Style.spacing.md
                spacing: Commons.Style.spacing.md

                FooterIcon { iconSize: 28 }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    FooterTitle { Layout.fillWidth: true }

                    CardText {
                        Layout.fillWidth: true
                        text: card.applicationName
                        opacity: 0.68
                        font.pixelSize: Commons.Style.font.caption
                        elide: Text.ElideRight
                    }
                }

                WorkspaceColumn {}
            }
        }
    }

    Component {
        id: floatingFooter

        RowLayout {
            spacing: Commons.Style.spacing.md

            FooterIcon { iconSize: 30 }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                FooterTitle { Layout.fillWidth: true }

                CardText {
                    Layout.fillWidth: true
                    text: card.applicationName
                    opacity: 0.62
                    font.pixelSize: Commons.Style.font.caption
                    elide: Text.ElideRight
                }
            }

            WorkspaceColumn {}
        }
    }

    Component {
        id: integratedFooter

        RowLayout {
            spacing: Commons.Style.spacing.md

            FooterIcon {}

            FooterTitle { Layout.fillWidth: true }

            CardText {
                text: "WS " + card.workspaceName
                color: card.focusedWindow ? card.currentColor : Commons.Color.menu.text
                opacity: card.focusedWindow ? 1 : 0.68
                font.pixelSize: Commons.Style.font.caption
                font.bold: true
            }
        }
    }

    Component {
        id: centeredFooter

        ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Commons.Style.spacing.md

                FooterIcon {}

                FooterTitle { Layout.maximumWidth: Math.max(1, card.width - Commons.Style.space(80)) }
            }

            CardText {
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: Math.max(1, card.width - Commons.Style.space(32))
                text: card.applicationName + "  ·  Workspace " + card.workspaceName
                color: card.focusedWindow ? card.currentColor : Commons.Color.menu.text
                opacity: card.focusedWindow ? 1 : 0.62
                font.pixelSize: Commons.Style.font.caption
                elide: Text.ElideRight
            }
        }
    }

    Behavior on x {
        enabled: card.controller.motionSettled

        NumberAnimation {
            duration: card.controller.previewAnimationDuration
            easing.type: card.controller.previewAnimationEasing
        }

    }

    Behavior on y {
        enabled: card.controller.motionSettled

        NumberAnimation {
            duration: card.controller.previewAnimationDuration
            easing.type: card.controller.previewAnimationEasing
        }

    }

    Behavior on width {
        enabled: card.controller.motionSettled

        NumberAnimation {
            duration: card.controller.previewAnimationDuration
            easing.type: card.controller.previewAnimationEasing
        }

    }

    Behavior on height {
        enabled: card.controller.motionSettled

        NumberAnimation {
            duration: card.controller.previewAnimationDuration
            easing.type: card.controller.previewAnimationEasing
        }

    }

    Behavior on opacity {
        enabled: card.controller.motionSettled

        NumberAnimation {
            duration: card.controller.previewFadeDuration
        }

    }

    // Springy motion pops the lift past its size and lets it settle.
    Behavior on scale {
        enabled: card.controller.motionSettled

        NumberAnimation {
            duration: card.controller.juiceSpring ? 320 : card.controller.previewFadeDuration
            easing.type: card.controller.juiceSpring ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 3
        }

    }

}
