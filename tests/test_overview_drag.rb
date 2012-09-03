#DESCRIPTION: Notes app drag and drop in overview
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

notes = [
  "one", "two", "three", "four", "five", "six"
]

def make_titles(notes)
  notes.each_with_index.map { |body, i| "#{i+1}. #{body}" }
end

puts "Creating notes..."
tester.verify_empty
tester.create_notes_fixture(notes)

titles = make_titles(notes)

puts "Opening the overview list..."
tester.tap_tool('toolbarOverviewIcon')
tester.verify_overview(titles)

puts "Dragging the first note down..."
tester.overview_tap_down("1. one")
sleep 1  # long press
tester.verify_overview([nil] + titles[1..-1])
tester.overview_drag_down(2)
tester.verify_overview(titles[1..2] + [nil] + titles[3..-1])
tester.overview_release
titles = titles[1..2] + titles[0..0] + titles[3..-1]
tester.verify_overview(titles)

puts "Checking that notes were rearranged..."
notes = notes[1..2] + notes[0..0] + notes[3..-1]
tester.tap_button("2. two")

notes.each_with_index { |body, i|
  tester.verify_page_number(i+1, notes.length)
  tester.verify_note(body)
  tester.flick_note_left
}

puts "Checking that placeholder note past end is correct..."
tester.verify_empty
tester.verify_next_note(notes[0])

tester.kill
