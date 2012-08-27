// Copyright (C) 2012 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

function upgradeSchema(db) {
    if (db.version == '') {
        db.changeVersion('', '1', function (tx) {
            tx.executeSql('CREATE TABLE notes (seq INTEGER, name TEXT)');
        })
    }
    if (db.version == '1') {
        db.changeVersion('1', '2', function (tx) {
            tx.executeSql('CREATE TABLE deleted_notes ('
               + 'delete_time TEXT, name TEXT, body TEXT)');
        })
    }
}

function openDb() {
    var db = openDatabaseSync('qmlnotes', '', 'Notes meta-information', 10000,
            upgradeSchema)
    if (db.version != '2')
        upgradeSchema(db);
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
            model.append({ "name": name, "title": title, "placeholder": false })
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
