function initDB(db) {
    db.changeVersion('', '1', function (tx) {
        tx.executeSql('CREATE TABLE notes (seq INTEGER, name TEXT)');
        var name = backend.new_note()
        tx.executeSql('INSERT INTO notes VALUES (?, ?)', [1, name])
    })
}

function populateList(model) {
    var db = openDatabaseSync('qmlnotes', '1', 'Notes meta-information', 10000,
         initDB)
    console.log(db.version)
    db.transaction(function (tx) {
        var results = tx.executeSql('SELECT name FROM notes ORDER BY seq');
        for (var i = 0; results.rows.item(i) != null; i++) {
            model.append({ "name": results.rows.item(i).name })
        }
        model.append({ "name": "" })
    })
}
