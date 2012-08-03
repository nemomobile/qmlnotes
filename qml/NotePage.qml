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

            height: editorview.height
            width: editorview.width
            cursorVisible: true
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            smooth: editorview.moving == false
            focus: true

            onCursorRectangleChanged: editorview.followY(cursorRectangle)
            onTextChanged: {
                if (backend.write_note("note1", text) == false) {
                    // Storage failed!
                    readOnly = true; // Avoid further data loss
                }
            }
            Component.onCompleted: text = backend.read_note("note1")
        }
    }

    ScrollDecorator {
        flickableItem: editorview
    }
}
