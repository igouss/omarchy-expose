import QtQuick
import QtQuick.Effects
import "DioramaLayout.js" as DioramaLayout
import qs.Commons as Commons

// One window standing on its workspace's slab as a block, its live preview on
// the top face. The selection's block rises. A click selects it; a click on
// the selection opens it. Quick Look unfolds the top face to fill the area.
Item {
    id: block

    required property var modelData
    required property var stack
    readonly property var controller: stack.overview

    // Slot, slab, and floor from one read of the snapshot.
    readonly property var spot: {
        const strata = block.stack.strata;
        const slot = strata.toplevels.indexOf(block.modelData);
        return slot >= 0
            ? { slot: slot, plane: strata.planeOf[slot], floor: strata.floors[slot] }
            : { slot: -1, plane: 0, floor: { u: 0, v: 0, width: 1, depth: 1 } };
    }
    readonly property bool inLayout: spot.slot >= 0
    readonly property var floor: spot.floor
    readonly property bool selected: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.selection
    readonly property bool previewed: stack.screenWindow.acceptsKeyboard && inLayout && modelData === controller.previewToplevel
    readonly property bool focusedWindow: modelData === controller.originToplevel

    // How high the block stands; the selection rises on a spring.
    property real rise: selected ? DioramaLayout.liftHeight : 0
    Behavior on rise {
        enabled: block.controller.motionSettled
        SpringAnimation {
            spring: block.controller.juiceSpring ? 3 : 5
            damping: block.controller.juiceSpring ? 0.22 : 0.6
            epsilon: 0.5
        }
    }
    readonly property real lidHeight: (DioramaLayout.blockHeight + rise + (selected ? stack.hop : 0)) * stack.build

    readonly property var baseCorners: stack.cornersOnScreen(floor, 0)
    readonly property var lidCorners: stack.cornersOnScreen(floor, lidHeight)
    readonly property var previewRect: controller.previewRectFor(modelData,
        Qt.rect(lidCorners[0].x, lidCorners[0].y, lidCorners[3].x - lidCorners[0].x, lidCorners[3].y - lidCorners[0].y), stack.width, stack.height, 0, 0)

    // 0 on the slab, 1 in Quick Look.
    property real lookBlend: previewed ? 1 : 0
    Behavior on lookBlend {
        enabled: block.controller.motionSettled
        NumberAnimation { duration: block.controller.previewAnimationDuration; easing.type: block.controller.previewAnimationEasing }
    }

    function mix(point, x, y) {
        return { x: point.x + (x - point.x) * block.lookBlend, y: point.y + (y - point.y) * block.lookBlend };
    }

    anchors.fill: parent
    visible: inLayout
    transform: Translate { y: block.inLayout && !block.previewed ? block.stack.dropFor(block.spot.plane) : 0 }
    z: previewed ? 100000 : stack.depthOrder(floor) + (selected ? 0.5 : 0)
    opacity: controller.previewToplevel && !previewed ? 0.2 : 1

    // A flat shadow cast down and to the right of the base.
    DioramaFace {
        p0: ({ x: block.baseCorners[0].x + block.lidHeight * 0.35 * block.stack.view.scale, y: block.baseCorners[0].y })
        px: ({ x: block.baseCorners[1].x + block.lidHeight * 0.35 * block.stack.view.scale, y: block.baseCorners[1].y })
        py: ({ x: block.baseCorners[2].x + block.lidHeight * 0.35 * block.stack.view.scale, y: block.baseCorners[2].y })
        color: "black"
        opacity: 0.32 * (1 - block.lookBlend)
    }

    // The two sides that face the viewer.
    DioramaFace {
        p0: block.lidCorners[2]
        px: block.lidCorners[3]
        py: block.baseCorners[2]
        color: Qt.darker(Commons.Color.accent, block.selected ? 1.6 : 2.6)
        opacity: 1 - block.lookBlend
    }
    DioramaFace {
        p0: block.lidCorners[1]
        px: block.lidCorners[3]
        py: block.baseCorners[1]
        color: Qt.darker(Commons.Color.accent, block.selected ? 2.2 : 3.4)
        opacity: 1 - block.lookBlend
    }

    // The lid: the live preview, unfolding to the Quick Look rect.
    Item {
        id: lidFace
        readonly property var p0: block.mix(block.lidCorners[0], block.previewRect.x, block.previewRect.y)
        readonly property var px: block.mix(block.lidCorners[1], block.previewRect.x + block.previewRect.width, block.previewRect.y)
        readonly property var py: block.mix(block.lidCorners[2], block.previewRect.x, block.previewRect.y + block.previewRect.height)
        width: Math.max(1, Math.hypot(px.x - p0.x, px.y - p0.y))
        height: Math.max(1, Math.hypot(py.x - p0.x, py.y - p0.y))
        transform: Matrix4x4 {
            matrix: {
                const m = DioramaLayout.faceMatrix(lidFace.p0, lidFace.px, lidFace.py, lidFace.width, lidFace.height);
                return Qt.matrix4x4(m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11], m[12], m[13], m[14], m[15]);
            }
        }

        Loader {
            anchors.fill: parent
            anchors.margins: -Commons.Style.space(5)
            active: block.selected && !block.previewed
            sourceComponent: Rectangle {
                radius: Commons.Style.space(8)
                color: Commons.Color.accent
                opacity: 0.8 * block.controller.selectionBreath
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1
                    blurMax: 32
                    autoPaddingEnabled: true
                }
            }
        }

        WindowThumbnail {
            id: thumbnail
            anchors.fill: parent
            radius: Commons.Style.space(4)
            toplevel: block.modelData
            live: block.controller.opened && block.inLayout

            Rectangle {
                anchors.fill: parent
                color: "white"
                opacity: punch.flash
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: thumbnail.radius
            color: "transparent"
            border.color: block.selected ? Commons.Color.accent : Qt.alpha(Commons.Color.accent, 0.35)
            border.width: Commons.Style.space(block.selected ? 2 : 1)
        }

        // The window the overview was opened from.
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Commons.Style.space(6)
            width: Commons.Style.space(10)
            height: width
            radius: width / 2
            visible: block.focusedWindow
            color: Commons.Color.accent
            border.color: Commons.Color.background
            border.width: Commons.Style.space(2)
        }

        JuicePunch {
            id: punch
            anchors.fill: parent
            controller: block.controller
            toplevel: block.modelData
        }

        CardPointer {
            controller: block.controller
            toplevel: block.modelData
            acceptsKeyboard: block.stack.screenWindow.acceptsKeyboard
            selected: block.selected
            previewed: block.previewed
        }
    }
}
