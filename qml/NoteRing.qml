import QtQuick 1.1
import com.nokia.meego 1.0

import "notes.js" as NoteScript

Item {
    id: notering

    property int spacing: 2
    property real globalFontScale: 1.0

    ListModel {
        id: listmodel

        Component.onCompleted: NoteScript.populateList(listmodel)
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
        // make the view snap to the new item when currentItem changes
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
    }
}
