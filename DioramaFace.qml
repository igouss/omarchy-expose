import QtQuick
import "DioramaLayout.js" as DioramaLayout

// A flat parallelogram on screen: its corner p0, its x edge ending at px and
// its y edge at py. Sized to its edges, so children and antialiasing work in
// near-screen pixels.
Rectangle {
    id: face

    required property var p0
    required property var px
    required property var py

    width: Math.max(1, Math.hypot(px.x - p0.x, px.y - p0.y))
    height: Math.max(1, Math.hypot(py.x - p0.x, py.y - p0.y))
    antialiasing: true
    transform: Matrix4x4 {
        matrix: {
            const m = DioramaLayout.faceMatrix(face.p0, face.px, face.py, face.width, face.height);
            return Qt.matrix4x4(m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11], m[12], m[13], m[14], m[15]);
        }
    }
}
