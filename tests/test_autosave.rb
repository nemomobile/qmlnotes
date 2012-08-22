#DESCRIPTION: New content is saved automatically
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

body = "Test autosave\n"

tester.verify_empty
tester.write_note(body)
tester.verify_note(body)

tester.restart

tester.verify_note(body)

tester.kill
