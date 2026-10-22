import QtQuick
import "HelixLayout.js" as HelixLayout
import qs.Commons as Commons

// The helix look: Strata's floors wound around a glowing spine like a spiral
// staircase, each window at its real place on its floor. The tower turns on a
// spring to bring the selection's floor to the front.
PlaneStack {
    id: look

    reach: HelixLayout.reach
    planeMaxWidth: width * 0.42
    planeMaxHeight: height * 0.34
    planeWord: "step"

    function placeAt(offset: real): var {
        return HelixLayout.placeFloor(offset, look.width, look.height, look.planeMaxHeight);
    }

    // The spine the floors turn around, between the floors in front and those behind.
    Rectangle {
        x: look.width / 2 - width / 2
        y: 0
        width: Commons.Style.space(6)
        height: look.height
        z: HelixLayout.spineZ(look.width) * 10 + 5
        radius: width / 2
        opacity: look.overview.previewToplevel ? 0.2 : 0.85
        gradient: Gradient {
            GradientStop { position: 0; color: "transparent" }
            GradientStop { position: 0.4; color: Commons.Color.accent }
            GradientStop { position: 0.75; color: Qt.alpha(Commons.Color.accent, 0.4) }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
