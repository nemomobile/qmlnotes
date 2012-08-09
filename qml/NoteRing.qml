import QtQuick 1.1
import com.nokia.meego 1.0

import "notes.js" as NoteScript

Item {
    id: notering

    property int spacing: 2

    ListModel {
        id: model

        Component.onCompleted: NoteScript.populateList(model)
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
        model: model
        delegate: delegate
        orientation: ListView.Horizontal
        snapMode: ListView.SnapToItem
        cacheBuffer: notering.width * 5
        spacing: notering.spacing
        // no idea what unit this is, but this value feels ok in tests
        // if deceleration is too low then it's hard to flick just 1 page.
        flickDeceleration: 8000

        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: notering.x
        preferredHighlightEnd: notering.x + notering.width
    }
}
