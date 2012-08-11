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

        Rectangle {
            width: parent.width
            height: titletext.height
            border.width: 2
            border.color: "black"

            Text {
                id: titletext
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: model.title
                font.pointSize: 24
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    pageStack.pop()
                    pageStack.currentPage.currentIndex = index + 1
                }
            }
        }
    }

    ListView {
        id: listview

        anchors.fill: parent
        model: listmodel
        delegate: delegate
    }
}
