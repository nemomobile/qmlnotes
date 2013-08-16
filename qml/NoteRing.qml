// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

import QtQuick 2.0
import com.nokia.meego 2.0

import "notes.js" as NoteScript

Page {
    id: notering
    objectName: "notering"

    property alias currentIndex: listview.currentIndex
    property int spacing: 2
    property real globalFontScale: 1.0
    property bool globalSelectActive: false

    ListModel {
        id: listmodel

        property int deleted_count;

        Component.onCompleted: {
            NoteScript.populateRing(listmodel);
            listview.currentIndex = 1;
            listview.positionViewAtIndex(1, ListView.Contain)
        }
    }

    Component {
        id: delegate

        FocusScope {
            // FocusScope has no geometry of its own
            x: note.x; y: note.y; height: note.height; width: note.width
            focus: ListView.isCurrentItem

            property Item note: note // to make listview.currentItem.note work

            Note {
                id: note
                name: model.name
                property int index: model.index
                width: notering.width; height: notering.height
                fontScale: globalFontScale
                selectActive: parent.focus && globalSelectActive

                function handlePinch(pinch) {
                    globalFontScale = globalFontScale * pinch.scale
                }

                onNewNote: NoteScript.registerNewNote(listmodel, index, name)

                Rectangle {
                    id: noteborder
                    anchors.left: note.right
                    anchors.top: note.top
                    anchors.bottom: note.bottom
                    width: notering.spacing
                    color: "black"
                    z: note.z + 1
                }
            }

            states: [
                State {
                    name: "DELETE"
                }
            ]

            transitions: [
                Transition {
                    to: "DELETE"
                    SequentialAnimation {
                        NumberAnimation {
                            target: note; property: "opacity"; to: 0
                            duration: 500; easing.type: Easing.Linear
                        }
                        ScriptAction {
                            script: NoteScript.deleteNote(listmodel, index)
                        }
                    }
                }
            ]
        }
    }

    ListView {
        id: listview
        objectName: "noteringView"

        anchors.fill: parent
        model: listmodel
        delegate: delegate
        orientation: ListView.Horizontal
        snapMode: ListView.SnapToItem
        spacing: notering.spacing
        // no idea what unit this is, but this value feels ok in tests
        // if deceleration is too low then it's hard to flick just 1 page.
        flickDeceleration: 8000
        pressDelay: 250

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: notering.x
        preferredHighlightEnd: notering.x + notering.width
        // make the view snap to the new item when currentIndex changes
        // (1 is the minimum duration, just 1 millisecond)
        highlightMoveDuration: 1
        // This makes the wraparound handling smoother
        boundsBehavior: Flickable.StopAtBounds

        onCurrentIndexChanged: {
            var max = listmodel.count - 1
            if (max < 2)
                return;  // listmodel not ready yet
            // Stay away from the edges; wrap around.
            // The listmodel has extra entries at the ends to allow this. 
            if (currentIndex == 0)
                currentIndex = max - 1
            else if (currentIndex == max)
                currentIndex = 1
        }

        Component.onCompleted: currentIndex = 1

        property int lastNote: count - 3
        property bool atNewNote: currentIndex == count - 2
    }

    Component {
        // wrap Overview in a Component so that it gets recreated every
        // time it is pushed; that way it reloads the note title list.
        id: overview

        Overview {
            onNoteDragged: NoteScript.moveNote(listmodel, oldNumber, newNumber)
        }
    }

    tools: ToolBarLayout {
        ToolIcon {
            objectName: 'toolbarOverviewIcon'
            iconSource: "../icons/icon-m-notes-overview.png"
            onClicked: {
                pageStack.push(overview)
                pageStack.currentPage.currentIndex = currentIndex - 1
            }
        }
        ToolIcon {
            // insert this as a placeholder to balance the toolbar
            objectName: 'toolbarFindIcon'
            iconSource: "../icons/icon-m-notes-search.png"
            onClicked: findbar.visible = !findbar.visible
        }
        Label {
            objectName: 'toolbarPageNumber'
            text: listview.atNewNote ? ""
                  : "" + listview.currentIndex + "/" + listview.lastNote
            // ToolBarLayout doesn't track the width correctly when the
            // text changes, so just set a width with some spare space here.
            Component.onCompleted: width = paintedWidth * 2
        }
        ToolIcon {
            objectName: 'toolbarSelectIcon'
            iconSource: "../icons/icon-m-notes-select.png"
            onClicked: globalSelectActive = !globalSelectActive

            Rectangle {
                // temporary measure until there is a -white icon for this
                border { color: "white"; width: 2 }
                width: 36; height: 36
                radius: 5
                anchors.centerIn: parent
                visible: globalSelectActive
                color: "transparent"
            }
        }
        ToolIcon {
            objectName: 'toolbarMenuIcon'
            iconId: noteMenu.status == DialogStatus.Closed
                     ? "icon-m-toolbar-view-menu"
                     : "icon-m-toolbar-view-menu-white";
            onClicked: (noteMenu.status == DialogStatus.Closed)
                       ? noteMenu.open() : noteMenu.close()
        }
    }

    Menu {
        id: noteMenu
        visualParent: notering

        MenuLayout {
            MenuItem {
                text: "Undelete Note";
                enabled: listmodel.deleted_count > 0
                onClicked: {
                    var index = currentIndex
                    NoteScript.undeleteNote(listmodel, index)
                    // focus on the newly undeleted note
                    currentIndex = index
                }
            }
            MenuItem {
                text: "Delete Note";
                enabled: !listview.atNewNote
                onClicked: {
                    if (!listview.atNewNote)
                        listview.currentItem.state = "DELETE"
                }
            }
        }
    }

    Rectangle {
        id: findbar
        objectName: "findBar"
        anchors.bottom: listview.bottom
        width: parent.width
        height: findbartextinput.height + 4
        visible: false
        border.color: "brown"
        border.width: 4
        color: "gray"
        z: listview.z + 1

        property alias text: findbartextinput.text

        function find(dir) {
            listview.currentItem.note.releaseSearch()
            var found = NoteScript.findFrom(listmodel, dir,
                listview.currentIndex, listview.currentItem.note.cursorPosition,
                text)
            if (found) {
                listview.currentIndex = found.page
                listview.currentItem.note.showSearch(
                    found.pos, found.pos + text.length)
            }
        }

        onVisibleChanged: listview.currentItem.note.releaseSearch()

        Text {
            id: findbarlabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "Find: "
            font.pointSize: 24
            height: parent.height
        }
        TextField {
            id: findbartextinput
            objectName: "findBarTextInput"
            anchors.left: findbarlabel.right
            anchors.right: findbartools.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - findbarlabel.width - findbartools.width
            font.pointSize: 24
            focus: findbar.visible
            onAccepted: findbar.find("next")
        }
        Row {
            id: findbartools
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            ToolIcon {
                objectName: "findBarPrev"
                iconId: 'toolbar-previous'
                enabled: findbar.text != ''
                onClicked: findbar.find("prev")
            }
            ToolIcon {
                objectName: "findBarNext"
                iconId: 'toolbar-next'
                enabled: findbar.text != ''
                onClicked: findbar.find("next")
            }
            ToolIcon {
                objectName: "findBarHide"
                iconId: 'toolbar-close-white'
                onClicked: findbar.visible = false
            }
        }
    }
}
