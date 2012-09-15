// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

import QtQuick 1.1

import "notes.js" as NoteScript

ListModel {
    id: notelist

    property int first: 1
    property int last: count - 3
    property int deleted_count;
    property bool loaded: false;

    Component.onCompleted: {
        NoteScript.populateRing(notelist);
        loaded = true
    }
}
