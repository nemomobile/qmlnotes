import QtQuick 1.1
import com.nokia.meego 1.0

Item {
    id: note

    property string name: ''
    onNameChanged: if (name != '') { editor.text = backend.read_note(name) }

    // fontScale and handlePinch are normally overridden by NoteRing in
    // order to have a uniform font scale for all notes, but they are
    // provided here in a way that allows Note to be used on its own too.
    property real fontScale: 1.0
    function handlePinch(pinch) { fontScale = fontScale * pinch.scale }

    Flickable {
        id: editorview

        anchors.fill: parent
        contentWidth: width
        contentHeight: editor.paintedHeight
        flickableDirection: Flickable.VerticalFlick 
        // pressDelay to prevent editor from opening the keyboard on flicks
        pressDelay: 250
        clip: true

        function followY(rect) {
            if (contentY >= rect.y) {
                contentY = rect.y;
            } else if (contentY + height <= rect.y + rect.height) {
                contentY = rect.y + rect.height - height;
            }
        }

        // The PinchArea has to be before the TextEdit, otherwise it
        // steals mouse press events that TextEdit uses to regulate
        // keyboard focus.
        PinchArea {
            anchors.fill: editor;

            onPinchFinished: note.handlePinch(pinch)
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
            font.pointSize: 24 * note.fontScale

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
