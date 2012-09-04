#DESCRIPTION: Notes can be deleted and undeleted
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

notes = [
  'What happen?',
  'Somebody set up us the bomb.',
  'We get signal.',
  'Main screen turn on.'
]

tester.verify_empty
tester.verify_page_number(nil, nil)

tester.verify_menu_disabled('Delete Note')
tester.verify_menu_disabled('Undelete Note')

puts "Creating sample notes..."
tester.create_notes_fixture(notes)
tester.verify_menu_enabled('Delete Note')
tester.verify_menu_disabled('Undelete Note')

puts "Deleting note 2..."
tester.flick_note_left
tester.flick_note_left
tester.flick_note_left
tester.verify_note(notes[1])
tester.verify_page_number(2, 4)

tester.tap_menu('Delete Note')
tester.verify_note(notes[2])
tester.verify_page_number(2, 3)
tester.verify_menu_enabled('Delete Note')
tester.verify_menu_enabled('Undelete Note')

puts "Undeleting at end..."
tester.flick_note_left
tester.flick_note_left
tester.verify_empty
tester.verify_menu_disabled('Delete Note')
tester.verify_menu_enabled('Undelete Note')

tester.tap_menu('Undelete Note')
tester.verify_note(notes[1])
tester.verify_page_number(4, 4)
tester.verify_menu_enabled('Delete Note')
tester.verify_menu_disabled('Undelete Note')

puts "Verifying note ring..."
tester.flick_note_left
[notes[0], notes[2], notes[3], notes[1]].each_with_index { |body, i|
  tester.flick_note_left
  tester.verify_note(body)
  tester.verify_page_number(i+1, 4)
}

tester.kill
