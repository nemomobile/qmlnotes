// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

import QtQuick 1.1
import com.nokia.meego 1.0

import "notes.js" as NoteScript

Page {
    id: overviewpage

    property alias currentIndex: listview.currentIndex

    signal noteDragged(int oldNumber, int newNumber)

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
                    console.log("long press at " + mouse.x + " " + mouse.y)
                    var conv = dragproxy.parent.mapFromItem(listview,
                                                            parent.x, parent.y)
                    console.log("conv to " + conv.x + " " + conv.y)
                    // First force the x value and skip the animation
                    dragproxy.x = conv.x
                    drageffect.complete()
                    // Then animate to x + 20
                    dragproxy.x = conv.x + 20
                    dragproxy.y = conv.y + 2
                    dragproxy.text = model.title
                    dragproxy.visible = true
                    // can't use parent.visible because that cancels our press
                    parent.opacity = 0
                    drag.target = dragproxy
                }

                onPositionChanged: {
                    if (drag.target == undefined)
                        return
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
                        listmodel.move(index, newindex, 1)
                    }
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

        NumberAnimation {
            id: scrollToEnd
            running: dragproxy.visible
                     && dragproxy.bottom > listview.bottom - 24
                     && listview.contentHeight > listview.height
            target: listview
            property: "contentY"
            to: Math.max(0, listview.contentHeight - listview.height)
            easing.type: Easing.Linear
            // use duration as a proxy to set speed
            duration: Math.abs(listview.contentY - listview.contentHeight
                               + listview.height) / listview.height
        }

        NumberAnimation {
            id: scrollToStart
            running: dragproxy.visible
                  && dragproxy.y < listview.y
                  && listview.contentHeight > listview.height
                  && listview.contentY > 0
            target: listview
            property: "contentY"
            to: 0
            easing.type: Easing.Linear
            // use duration as a proxy to set speed
            duration: listview.contentY / listview.height
        }

        onContentHeightChanged: console.log("content height: " + contentHeight)
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
