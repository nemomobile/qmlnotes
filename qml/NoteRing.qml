// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

import QtQuick 1.1
import com.nokia.meego 1.0

import "notes.js" as NoteScript

Page {
    id: notering

    property alias currentIndex: listview.currentIndex
    property int spacing: 2
    property real globalFontScale: 1.0
    property bool globalSelectActive: false
    property ListModel notemodel

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

                onNewNote: NoteScript.registerNewNote(notemodel, index, name)

                Rectangle {
                    id: noteborder
                    anchors.left: note.right
                    anchors.top: note.top
                    anchors.bottom: note.bottom
                    width: notering.spacing
                    color: "brown"
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
                            script: NoteScript.deleteNote(notemodel, index)
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
        model: notemodel
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
            if (!loaded)
                return;
            // Stay away from the edges; wrap around.
            // The notemodel has extra entries at the ends to allow this. 
            if (currentIndex < notemodel.first)
                currentIndex = notemodel.last + 1
            else if (currentIndex > notemodel.last + 1)
                currentIndex = notemodel.first
        }

        property bool loaded: notemodel.loaded
        onLoadedChanged: {
            currentIndex = 1
            // for some reason the highlight doesn't focus on it on its own,
            // though it does do that when currentIndex changes in other places
            positionViewAtIndex(1, ListView.Contain)
        }

        property bool atNewNote: currentIndex == count - 2
    }

    Component {
        // wrap Overview in a Component so that it gets recreated every
        // time it is pushed; that way it reloads the note title list.
        id: overview

        Overview {
            notemodel: notering.notemodel
            onNoteDragged: NoteScript.moveNote(notemodel, oldNumber, newNumber)
        }
    }

    tools: ToolBarLayout {
        ToolIcon {
            objectName: 'toolbarOverviewIcon'
            iconId: "toolbar-pages-all"
            onClicked: {
                pageStack.push(overview)
                pageStack.currentPage.currentIndex = currentIndex - 1
            }
        }
        ToolIcon {
            // insert this as a placeholder to balance the toolbar
            objectName: 'toolbarFindIcon'
            iconId: "toolbar-search"
            onClicked: findbar.visible = !findbar.visible
        }
        Label {
            objectName: 'toolbarPageNumber'
            text: listview.atNewNote ? ""
                  : "" + listview.currentIndex + "/" + notemodel.last
            // ToolBarLayout doesn't track the width correctly when the
            // text changes, so just set a width with some spare space here.
            Component.onCompleted: width = paintedWidth * 2
        }
        ToolIcon {
            objectName: 'toolbarSelectIcon'
            iconId: "toolbar-cut-paste"
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
            iconId: theme.inverted ? "icon-m-toolbar-view-menu-white"
                                   : "icon-m-toolbar-view-menu";
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
                enabled: notemodel.deleted_count > 0
                onClicked: {
                    var index = currentIndex
                    NoteScript.undeleteNote(notemodel, index)
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
            var found = NoteScript.findFrom(notemodel, dir,
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
