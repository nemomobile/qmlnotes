function openDb() {
    return openDatabaseSync('qmlnotes', '1', 'Notes meta-information', 10000,
        function (db) {  // initialization callback
            db.changeVersion('', '1', function (tx) {
                tx.executeSql('CREATE TABLE notes (seq INTEGER, name TEXT)');
            })
        })
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
    db.transaction(function (tx) {
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
    })
}

function populateTitleList(model) {
    var db = openDb()
    db.transaction(function (tx) {
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
                    + model.get(index).name + " in index")
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
