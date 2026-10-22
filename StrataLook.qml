import QtQuick
import "StrataLayout.js" as StrataLayout

// The strata look: every workspace a glass plane laid back in perspective,
// stacked like floors, each window at its real place on its plane. The camera
// springs to the plane that holds the selection.
PlaneStack {
    id: look

    reach: StrataLayout.reach
    planeWord: "floor"

    function placeAt(offset: real): var {
        return StrataLayout.placePlane(offset, look.width, look.height, look.planeMaxHeight);
    }
}
