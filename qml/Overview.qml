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
            id: notebutton
            // Use a private MouseArea in order to catch long clicks
            property alias pressed: buttonmouser.pressed

            width: listview.width
            text: model.title
            font.pointSize: 24
            visible: !model.placeholder

            onClicked: {
                pageStack.pop()
                pageStack.currentPage.currentIndex = index + 1
            }

            Component.onCompleted: buttonmouser.clicked.connect(clicked)

            MouseArea {
                id: buttonmouser

                anchors.fill: parent

                onPressAndHold: dragger.startDragging(parent, index)
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

    MouseArea {
        id: dragger

        anchors.fill: parent
        enabled: false
        drag.target: dragproxy
        preventStealing: enabled

        property int index
        property int origIndex

        function startDragging(item, index) {
            dragger.index = index
            dragger.origIndex = index
            dragproxy.x = item.x
            dragproxy.y = item.y
            dragproxy.text = listmodel.get(index).title
            listmodel.setProperty(index, 'placeholder', true)
            enabled = true
        }

        onPositionChanged: {
            var listy = listview.mapFromItem(dragger, 0,
                                  dragproxy.y + dragproxy.height / 2).y
            var newitem = listview.childAt(listview.x + listview.width / 2,
                                           listy)
            if (newitem && newitem.index != index) {
                listmodel.move(index, newitem.index, 1)
                index = newitem.index
            }
        }

        onReleased: {
            enabled = false
            listmodel.setProperty(index, 'placeholder', false)
        }

        onCanceled: {
            enabled = false
            listmodel.setProperty(index, 'placeholder', false)
            listmodel.move(index, origIndex, 1)
        }

        Button {
            // styled as a button but not clickable
            // the parent MouseArea overrides it
            id: dragproxy

            width: listview.width
            font.pointSize: 24
            visible: parent.enabled
        }
    }
}
