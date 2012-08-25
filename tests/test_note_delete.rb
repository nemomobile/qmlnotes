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
notes.each { |body|
  tester.write_note(body)
  tester.verify_note(body)
  tester.verify_menu_enabled('Delete Note')
  tester.verify_menu_disabled('Undelete Note')
  tester.flick_note_left
}

# Should have ended up at the empty note
tester.verify_empty
tester.verify_menu_disabled('Delete Note')
tester.verify_menu_disabled('Undelete Note')

puts "Deleting note 2..."
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

puts "Deleting two notes"
tester.flick_note_right
tester.verify_page_number(3, 4)
tester.verify_menu_enabled('Delete Note')
tester.verify_menu_disabled('Undelete Note')
tester.tap_menu('Delete Note')
tester.verify_page_number(3, 3)
tester.verify_menu_enabled('Delete Note')
tester.verify_menu_enabled('Undelete Note')
tester.tap_menu('Delete Note')
tester.verify_page_number(nil, nil)
tester.verify_menu_disabled('Delete Note') # should be at empty note now
tester.verify_menu_enabled('Undelete Note')

puts "Verifying that deleted notes can be restored in next session..."
tester.restart

tester.verify_note(notes[0])
tester.verify_page_number(1, 2)
tester.verify_menu_enabled('Delete Note')
tester.verify_menu_enabled('Undelete Note')
tester.flick_note_left
tester.verify_note(notes[2]) # not notes[1], we moved it already
tester.verify_page_number(2, 2)

puts "Undeleting in middle..."
tester.tap_menu('Undelete Note')
tester.verify_note(notes[1])
tester.verify_page_number(2, 3)
tester.verify_menu_enabled('Delete Note')
tester.verify_menu_enabled('Undelete Note')

tester.tap_menu('Undelete Note')
tester.verify_note(notes[3])
tester.verify_page_number(2, 4)
tester.verify_menu_enabled('Delete Note')
tester.verify_menu_disabled('Undelete Note')

puts "Verifying overview..."
[notes[0], notes[3], notes[1], notes[2]].each_with_index { |body, i|
  tester.tap_tool('toolbarOverviewIcon')
  title = body.split("\n")[0]
  tester.tap_button("#{i+1}. #{title}")
  tester.verify_note(body)
  tester.verify_page_number(i+1, 4)
}

tester.kill
