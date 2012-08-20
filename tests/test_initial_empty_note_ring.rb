#DESCRIPTION: Notes app starts with empty notes in a ring
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

tester.verify_empty
tester.verify_index(1)
tester.flick_note_left
tester.verify_empty
tester.verify_index(1)
tester.flick_note_right
tester.verify_empty
tester.verify_index(1)
