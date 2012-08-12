// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

import QtQuick 1.1
import com.nokia.meego 1.0

import "notes.js" as NoteScript

Page {
    id: overviewpage

    property alias currentIndex: listview.currentIndex

    ListModel {
        id: listmodel

        Component.onCompleted: NoteScript.populateTitleList(listmodel)
    }

    Component {
        id: delegate

        Button {
            width: listview.width
            text: model.title
            font.pointSize: 24

            onClicked: {
                pageStack.pop()
                pageStack.currentPage.currentIndex = index + 1
            }
        }
    }

    Button {
        id: newbutton

        anchors.top: parent.top
        width: parent.width
        text: "New note"

        onClicked: {
            pageStack.pop()
            pageStack.currentPage.currentIndex = listview.count + 1
        }
    }

    ListView {
        id: listview

        anchors {
            top: newbutton.bottom; bottom: parent.bottom
            left: parent.left; right: parent.right
        }
        clip: true  // don't overlap the new note button
        model: listmodel
        delegate: delegate
    }

    ScrollDecorator {
        flickableItem: listview
    }

    Label {
        id: emptylistcomforter

        anchors.centerIn: listview
        visible: listview.count == 0
        font.pointSize: 40
        text: "No notes yet"
        color: "gray"
    }
}
