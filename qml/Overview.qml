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

            onClicked: {
                pageStack.pop()
                pageStack.currentPage.currentIndex = index + 1
            }

            Component.onCompleted: buttonmouser.clicked.connect(clicked)

            MouseArea {
                id: buttonmouser

                anchors.fill: parent
                preventStealing: drag.active

                property int dragStartIndex

                onPressAndHold: {
                    dragStartIndex = index
                    var conv = dragproxy.parent.mapFromItem(listview,
                                                            parent.x, parent.y)
                    dragproxy.x = conv.x
                    dragproxy.y = conv.y
                    dragproxy.text = model.title
                    dragproxy.visible = true
                    // can't use parent.visible because that cancels our press
                    parent.opacity = 0
                    drag.target = dragproxy
                }

                onPositionChanged: {
                    // for some reason, directly mapping dragproxy's coords
                    // to the listview coords gives wrong answers, so start
                    // from 0 and do it manually.
                    var adj = listview.mapFromItem(dragproxy.parent, 0, 0).y
                    // adding adj gives listview view coords
                    // then add contentY to get listview content coords
                    var newindex = listview.indexAt(0,
                         listview.contentY + adj
                         + dragproxy.y + dragproxy.height / 2)
                    if (newindex >= 0 && newindex != index) {
                        console.log("Moving from " + index + " to " + newindex)
                        listmodel.move(index, newindex, 1)
                    }
                }

                onReleased: {
                    console.log("onReleased")
                    drag.target = undefined
                    dragproxy.visible = false
                    parent.opacity = 100
                }

                onCanceled: {
                    console.log("onCanceled")
                    listmodel.move(index, dragStartIndex, 1)
                    drag.target = undefined
                    dragproxy.visible = false
                    parent.opacity = 100
                }
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

    Button {
        // styled as a button but not used for clicking
        // it is only active while the dragger has control
        id: dragproxy

        width: listview.width
        font.pointSize: 24
        visible: false
    }
}
