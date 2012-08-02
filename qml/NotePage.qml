import QtQuick 1.1
import com.nokia.meego 1.0

Page {
    anchors.fill: parent

    Flickable {
        id: editorview

        anchors.fill: parent
        contentWidth: width
        contentHeight: editor.paintedHeight
        flickableDirection: Flickable.VerticalFlick 
        clip: true

        function followY(rect) {
            if (contentY >= rect.y) {
                contentY = rect.y;
            } else if (contentY + height <= rect.y + rect.height) {
                contentY = rect.y + rect.height - height;
            }
        }

        TextEdit {
            id: editor

            anchors.fill: parent
            focus: true
            smooth: editorview.moving == false

            onCursorRectangleChanged: editorview.followY(cursorRectangle)
        }
    }

    ScrollDecorator {
        flickableItem: editorview
    }
}
