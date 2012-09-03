#DESCRIPTION: New content is saved automatically
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

body = "Test autosave\n\n" +
"A process cannot be understood by stopping it." +
" Understanding must move with the flow of the process," +
" must join it and flow with it."

tester.verify_empty
tester.write_note(body)
tester.verify_note(body)

tester.restart

tester.verify_note(body)

tester.kill
