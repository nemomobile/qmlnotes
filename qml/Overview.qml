// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

import QtQuick 1.1
import com.nokia.meego 1.0

import "notes.js" as NoteScript

Page {
    id: overviewpage

    property alias currentIndex: listview.currentIndex
    property ListModel notemodel

    signal noteDragged(int oldNumber, int newNumber)

    Component {
        id: delegate

        Button {
            objectName: 'overviewbutton'
            // Use a private MouseArea in order to catch long clicks
            property alias pressed: buttonmouser.pressed
            property string name: model.name

            width: listview.width
            // Filter out the notering's sentinels
            visible: index >= notemodel.first && index <= notemodel.last
            height: visible ? implicitHeight : 0
            text: "" + index + "."
            font.pointSize: 24

            onNameChanged: {
                text = "" + index + ". " + backend.read_note(name).split("\n")[0]
            }

            onClicked: {
                pageStack.pop()
                pageStack.currentPage.currentIndex = index
            }

            Component.onCompleted: buttonmouser.clicked.connect(clicked)

            MouseArea {
                id: buttonmouser

                anchors.fill: parent
                preventStealing: drag.active

                property int dragStartIndex

                onPressAndHold: {
                    dragStartIndex = index
                    // First force the x value and skip the animation
                    dragproxy.x = parent.x - listview.contentX + listview.x
                    drageffect.complete()
                    // Then animate to x + 20
                    dragproxy.x = dragproxy.x + 20
                    dragproxy.y = parent.y - listview.contentY + listview.y
                    dragproxy.text = text
                    dragproxy.visible = true
                    // can't use parent.visible because that cancels our press
                    parent.opacity = 0
                    drag.target = dragproxy
                }

                onPositionChanged: {
                    if (drag.target == undefined)
                        return
                    var dy = dragproxy.y - listview.y + listview.contentY
                    // get item under dragproxy's center line
                    dy += dragproxy.height / 2
                    var newindex = listview.indexAt(0, dy)
                    // go to first or last position if dy is outside the list
                    if (newindex < notemodel.first && dy < 0)
                        newindex = notemodel.first
                    if (newindex < 0 && dy > listview.contentHeight)
                        newindex = notemodel.last
                    // move the invisible button to where the dragproxy
                    // would be dropped if it were released right now
                    if (newindex >= notemodel.first && newindex != index)
                        notemodel.move(index, newindex, 1)
                }

                onReleased: {
                    if (drag.target == undefined)
                        return
                    drag.target = undefined
                    dragproxy.visible = false
                    parent.opacity = 100
                    if (dragStartIndex != index) {
                        // emit signal with 1-based page numbers
                        noteDragged(dragStartIndex + 1, index + 1)
                    }
                }

                onCanceled: {
                    if (drag.target == undefined)
                        return
                    notemodel.move(index, dragStartIndex, 1)
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
            pageStack.currentPage.currentIndex = notemodel.last + 1
        }
    }

    ListView {
        id: listview
        objectName: 'overviewlist'

        anchors {
            top: newbutton.bottom; bottom: parent.bottom
            left: parent.left; right: parent.right
        }
        clip: true  // don't overlap the new note button
        model: notemodel
        delegate: delegate

        SmoothedAnimation {
            id: scrollToEnd
            running: dragproxy.visible
                     && dragproxy.y + dragproxy.height / 2
                          > listview.y + listview.height
                     && listview.contentHeight > listview.height
            target: listview
            property: "contentY"
            to: Math.max(0, listview.contentHeight - listview.height)
        }

        SmoothedAnimation {
            id: scrollToStart
            running: dragproxy.visible
                  && dragproxy.y < listview.y
                  && listview.contentHeight > listview.height
                  && listview.contentY > 0
            target: listview
            property: "contentY"
            to: 0
        }
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
        objectName: 'dragproxy'

        width: listview.width
        font.pointSize: 24
        visible: false
        z: parent.z + 2

        property bool pressed: true // always style as pressed

        Behavior on x {
            NumberAnimation {
                id: drageffect
                duration: 50
                easing.type: Easing.OutBack
                easing.overshoot: 20
            }
        }
    }

    tools: ToolBarLayout {
        ToolIcon {
            objectName: 'toolbarBackFromOverview'
            iconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }
}
