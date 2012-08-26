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

            Note {
                id: note
                name: model.name
                property int index: model.index
                width: notering.width; height: notering.height
                fontScale: globalFontScale

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
                            script: NoteScript.deleteNote(listmodel, index)
                        }
                    }
                }
            ]
        }
    }

    ListView {
        id: listview

        anchors.fill: parent
        model: listmodel
        delegate: delegate
        orientation: ListView.Horizontal
        snapMode: ListView.SnapToItem
        cacheBuffer: notering.width * 5
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

        onCurrentIndexChanged: {
            var max = listmodel.count - 1
            if (max < 2)
                return;  // listmodel not ready yet
            // Stay away from the edges; wrap around.
            // The listmodel is specially designed for this.
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

        Overview { }
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
        Label {
            objectName: 'toolbarPageNumber'
            text: listview.atNewNote ? ""
                  : "" + listview.currentIndex + "/" + listview.lastNote
            // ToolBarLayout doesn't track the width correctly when the
            // text changes, so just set a width with some spare space here.
            Component.onCompleted: width = paintedWidth * 1.5
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
}
