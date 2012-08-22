#DESCRIPTION: Page numbers reflect current state
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

notes = [
  "Test page numbers",
  "Test page 2",
  "Test page 3"
]

tester.verify_empty
tester.verify_page_number(nil, nil)

puts "Creating three notes..."
tester.write_note(notes[0])
tester.verify_note(notes[0])
tester.verify_page_number(1, 1)

tester.flick_note_left
tester.verify_page_number(nil, nil)
tester.write_note(notes[1])
tester.verify_note(notes[1])
tester.verify_page_number(2, 2)

tester.flick_note_left
tester.verify_page_number(nil, nil)
tester.write_note(notes[2])
tester.verify_note(notes[2])
tester.verify_page_number(3, 3)

puts "Verifying page numbers..."
tester.flick_note_right
tester.verify_note(notes[1])
tester.verify_page_number(2, 3)

tester.flick_note_right
tester.verify_note(notes[0])
tester.verify_page_number(1, 3)

tester.flick_note_right
tester.verify_empty
tester.verify_page_number(nil, nil)

tester.flick_note_right
tester.verify_note(notes[2])
tester.verify_page_number(3, 3)

tester.kill
