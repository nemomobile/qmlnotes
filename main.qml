import QtQuick 1.1
import com.nokia.meego 1.0
import "qml"

PageStackWindow {
    initialPage: Page {
        anchors.fill: parent

        NoteRing {
            anchors.fill: parent
        }
    }
}
