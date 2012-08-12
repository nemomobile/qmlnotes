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
            id: titletext
            width: listview.width
            text: model.title
            font.pointSize: 24

            onClicked: {
                pageStack.pop()
                pageStack.currentPage.currentIndex = index + 1
            }
        }
    }

    ListView {
        id: listview

        anchors.fill: parent
        model: listmodel
        delegate: delegate
    }

    ScrollDecorator {
        flickableItem: listview
    }
}
