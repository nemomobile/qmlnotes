// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

import QtQuick 2.0
import com.nokia.meego 2.0

Item {
    id: note

    property string name: ''
    property alias text: editor.text
    property alias cursorPosition: editor.cursorPosition

    onNameChanged: {
        if (name == '' || editor.busy)
            return;
        editor.busy = true;
        text = backend.read_note(name);
        editor.busy = false;
    }

    property alias selectActive: editor.selectByMouse

    onSelectActiveChanged: if (selectActive) editor.selectAll()

    signal newNote;

    // fontScale and handlePinch are normally overridden by NoteRing in
    // order to have a uniform font scale for all notes, but they are
    // provided here in a way that allows Note to be used on its own too.
    property real fontScale: 1.0
    function handlePinch(pinch) { fontScale = fontScale * pinch.scale }

    function showSearch(from, to) {
        editor.select(to, from)  // this leaves the cursor at "from"
        // center view on selection
        var top = editor.positionToRectangle(from)
        var bot = editor.positionToRectangle(to - 1)
        var destY = (top.y + bot.y + bot.height) / 2 - editorview.height / 2
        editorview.contentY = Math.max(0, destY)
    }
    function releaseSearch() { editor.deselect() }

    Image {
        id: background

        anchors.fill: parent
        fillMode: Image.Stretch
        source: width > height ? "../images/notes-background-landscape.jpg"
                               : "../images/notes-background-portrait.jpg"
    }

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
            activeFocusOnPress: !note.selectActive

            // this keeps it from immediately saving after loading, etc.
            property bool busy: false

            // keep the cursor position in view when editing
            onCursorRectangleChanged: editorview.followY(cursorRectangle)
            // ... or when the virtual keyboard pops up
            onHeightChanged: editorview.followY(cursorRectangle)
            onTextChanged: {
                if (busy)
                    return;
                busy = true;
                if (note.name == '') {
                    note.name = backend.new_note();
                    note.newNote()
                }
                if (backend.write_note(note.name, text) == false) {
                    console.log("Storage failed on " + note.name);
                    readOnly = true; // Avoid further data loss
                }
                busy = false;
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

    Row {
        id: cutnpaster
        visible: note.selectActive
        anchors.bottom: editorview.bottom
        anchors.right: editorview.right

        ToolIcon {
            iconSource: "../icons/icon-m-notes-cut.png";
            enabled: editor.selectionStart < editor.selectionEnd
            onClicked: editor.cut()
        }
        ToolIcon {
            iconSource: "../icons/icon-m-notes-copy.png";
            enabled: editor.selectionStart < editor.selectionEnd
            onClicked: editor.copy()
        }
        ToolIcon {
            iconSource: "../icons/icon-m-notes-paste.png";
            enabled: editor.canPaste
            onClicked: editor.paste()
        }
    }

    ScrollDecorator {
        flickableItem: editorview
    }
}
