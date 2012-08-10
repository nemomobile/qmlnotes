function initDB(db) {
    db.changeVersion('', '1', function (tx) {
        tx.executeSql('CREATE TABLE notes (seq INTEGER, name TEXT)');
        var name = backend.new_note()
        tx.executeSql('INSERT INTO notes VALUES (?, ?)', [1, name])
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
function populateList(model) {
    var db = openDatabaseSync('qmlnotes', '1', 'Notes meta-information', 10000,
         initDB)
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
        }
    })

    listview.currentIndex = 1
}
