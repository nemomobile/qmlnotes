// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

.import QtQuick.LocalStorage 2.0 as Sql

function upgradeSchema(db) {
    if (db.version === '') {
        db.changeVersion('', '1.0', function (tx) {
            tx.executeSql('CREATE TABLE notes (seq INTEGER, name TEXT)');
            tx.executeSql('CREATE TABLE deleted_notes ('
               + 'delete_time TEXT, name TEXT, body TEXT)');
        })
    }
}

function openDb() {
    var db = Sql.LocalStorage.openDatabaseSync('qmlnotes', '', 'Notes meta-information', 10000,
            upgradeSchema)

    return db;
}

// The model is populated in a slightly odd way to preserve the
// illusion of a circular list. The first element is blank.
// Then come the notes, then another blank, and then the first note again.
// The currentIndex is never allowed to be at the first or last element.
// If it reaches the first element, it's moved to the other blank note
// at the end. If it reaches the last element, it's moved to the first
// real note.
// There's an exceptional state if there are no real notes yet.
// Then there are just 3 blanks, and the currentIndex is forced to
// stay at the middle one.
function populateRing(model) {
    var db = openDb()
    db.readTransaction(function (tx) {
        model.clear()
        var results = tx.executeSql('SELECT name FROM notes ORDER BY seq');
        model.append({ "name": "" })
        for (var i = 0; results.rows.item(i) != null; i++) {
            model.append({ "name": results.rows.item(i).name })
        }
        model.append({ "name": "" })
        if (results.rows.length > 0) {
            model.append({ "name": results.rows.item(0).name })
        } else {
            model.append({ "name": "" })
        }
        results = tx.executeSql('SELECT COUNT(*) AS c FROM deleted_notes');
        model.deleted_count = results.rows.item(0).c;
    })
}

function populateTitleList(model) {
    var db = openDb()
    db.readTransaction(function (tx) {
        model.clear()
        var results = tx.executeSql('SELECT seq, name FROM notes ORDER BY seq');
        for (var i = 0; results.rows.item(i) != null; i++) {
            var name = results.rows.item(i).name
            var text = backend.read_note(name)
            var title = text.split("\n")[0]
            title = "" + results.rows.item(i).seq + ". " + title
            model.append({ "name": name, "title": title })
        }
    })
}

function registerNewNote(model, index, name) {
    if (model.get(index).name != '') {
        console.log("Internal error! trying to overwrite "
                    + model.get(index).name + " in index");
        return;
    }

    model.set(index, { "name": name })
    if (model.count == 3) { // convert from special case
        model.append({ "name": name})
    } else {
        model.insert(index + 1, { "name": ""})
    }

    var db = openDb();
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO notes (seq, name) VALUES (?, ?)',
                      [index, name])
    })
}

function moveNote(listmodel, oldIndex, newIndex) {
    var db = openDb();
    db.transaction(function (tx) {
        // Perform this as a rotation of a range of sequence numbers
        // for example moving 2 to position 4 in a sequence [1,2,3,4,5]
        // means mapping the [2,3,4] part to [3,4,2] which is a left rotation.
        var rangeStart = Math.min(oldIndex, newIndex)
        var rangeEnd = Math.max(oldIndex, newIndex)
        var rangeLen = rangeEnd - rangeStart + 1
        var adj = oldIndex < newIndex ? rangeLen - 1 : +1
        // adjust seq to be 0-based from rangeStart, then adjust and mod,
        // then add rangeStart back in again.
        tx.executeSql('UPDATE notes SET seq = ((seq - ? + ?) % ?) + ?'
                    + 'WHERE seq >= ? AND seq <= ?',
            [rangeStart, adj, rangeLen, rangeStart, rangeStart, rangeEnd])
    })
    listmodel.move(oldIndex, newIndex, 1)
    if (oldIndex == 1 || newIndex == 1) {
        // fix up the sentinel at the end
        listmodel.setProperty(listmodel.count - 1,
                              "name", listmodel.get(1).name)
    }
}

function deleteNote(model, index, body) {
    var db = openDb();
    var name = model.get(index).name;
    var body = backend.read_note(name);
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO deleted_notes (delete_time, name, body)'
                     + ' VALUES (datetime(?), ?, ?)', ['now', name, body])
        tx.executeSql('DELETE FROM notes WHERE seq = ?', [index]);
        tx.executeSql('UPDATE notes SET seq = seq - 1 WHERE seq > ?', [index])
        model.deleted_count += 1
    })
    model.remove(index);
    backend.delete_note(name);
}

function undeleteNote(model, index) {
    // undelete the most recent note and insert it at the current index
    var db = openDb();
    var name = null;
    var body = null;
    db.transaction(function (tx) {
        var results = tx.executeSql(
            'SELECT * FROM deleted_notes ORDER BY delete_time DESC LIMIT 1');
        if (results.rows.length == 0)
            return;
        var row = results.rows.item(0);
        name = row.name;
        body = row.body;
        tx.executeSql('DELETE FROM deleted_notes WHERE ' +
                      'delete_time = ? AND name = ? AND body = ?',
                      [row.delete_time, name, body])
        model.deleted_count -= 1
        // can the name be reused?
        results = tx.executeSql('SELECT 1 FROM notes WHERE name = ?', [name])
        if (results.rows.length > 0 || backend.read_note(name) != '')
            name = backend.new_note();
        tx.executeSql('UPDATE notes SET seq = seq + 1 WHERE seq >= ?', [index])
        tx.executeSql('INSERT INTO notes (seq, name) VALUES (?, ?)',
                      [index, name])
        backend.write_note(name, body)
        model.insert(index, { "name": name })
    })
}

function findFrom(model, dir, index, pos, text) {
    var pages = model.count - 3
    if (pages <= 0)
        return undefined   // empty ring
    if (index == 0 || index > pages) // at empty note
        index = 1
    if (dir == "next")
        return _findNext(model, index, pos, text)
    else
        return _findPrev(model, index, pos, text)
}

function _findNext(model, index, pos, text) {
    var note = backend.read_note(model.get(index).name)
    // If the search string is all lowercase then do a case insensitive search
    if (text.toLowerCase() == text)
        note = note.toLowerCase()
    var found = note.substring(pos + 1).indexOf(text)
    if (found >= 0)
        return { 'page': index, 'pos': found + pos + 1 }

    // Not found in current note. Try going around the ring.
    var pages = model.count - 3
    for (var n = 1; n < pages; n++) {
        var i = index + n
        if (i > pages)
            i = i - pages + 1
        var note_i = backend.read_note(model.get(i).name)
        if (text.toLowerCase() == text)
            note_i = note_i.toLowerCase()
        found = note_i.indexOf(text)
        if (found >= 0)
            return { 'page': i, 'pos': found }
    }

    // Not found in other notes. Try wrapping around to current note.
    found = note.substring(0, pos + text.length).indexOf(text)
    if (found >= 0)
        return { 'page': index, 'pos': found }
}

function _findPrev(model, index, pos, text) {
    var note = backend.read_note(model.get(index).name)
    // If the search string is all lowercase then do a case insensitive search
    if (text.toLowerCase() == text)
        note = note.toLowerCase()
    var found = note.substring(0, pos).lastIndexOf(text)
    if (found >= 0)
        return { 'page': index, 'pos': found }

    // Not found in current note. Try going around the ring.
    var pages = model.count - 3
    for (var n = 1; n < pages; n++) {
        var i = index - n
        if (i < 1)
            i = i + pages
        var note_i = backend.read_note(model.get(i).name)
        if (text.toLowerCase() == text)
            note_i = note_i.toLowerCase()
        found = note_i.lastIndexOf(text)
        if (found >= 0)
            return { 'page': i, 'pos': found }
    }

    // Not found in other notes. Try wrapping around to current note.
    found = note.substring(pos).lastIndexOf(text)
    if (found >= 0)
        return { 'page': index, 'pos': found + pos }
}
