import QtQuick 1.1
import com.nokia.meego 1.0

Item {
    id: note

    property string name: ''
    onNameChanged: if (name != '') { editor.text = backend.read_note(name) }

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
            font.pointSize: 24 * fontScale

            property real fontScale: 1.0

            // keep the cursor position in view when editing
            onCursorRectangleChanged: editorview.followY(cursorRectangle)
            // ... or when the virtual keyboard pops up
            onHeightChanged: editorview.followY(cursorRectangle)
            onTextChanged: {
                if (note.name == '')
                    note.name = backend.new_note();
                if (backend.write_note(note.name, text) == false) {
                    console.log("Storage failed on " + note.name);
                    readOnly = true; // Avoid further data loss
                }
            }
        }

        PinchArea {
            anchors.fill: editor;

            onPinchFinished: editor.fontScale = editor.fontScale * pinch.scale
        }

        Rectangle {
            id: titleshade

            x: editor.x; y: editor.y; width: editorview.width
            height: editor.font.pixelSize * 1.25

            color: "brown"
            opacity: 0.2
        }

    }

    ScrollDecorator {
        flickableItem: editorview
    }
}
