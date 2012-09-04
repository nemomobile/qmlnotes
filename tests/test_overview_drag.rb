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

puts "Testing effect of long press..."
tester.overview_tap_down("2. two")
sleep 1  # long press
tester.verify_overview(titles[0..0] + [nil] + titles[2..-1])
tester.overview_release
tester.verify_overview(titles)

puts "Dragging the first note down..."
tester.overview_drag_down("1. one", 2)
titles = titles[1..2] + titles[0..0] + titles[3..-1]
tester.verify_overview(titles)

puts "Checking that notes were rearranged..."
notes = notes[1..2] + notes[0..0] + notes[3..-1]
tester.tap_overview("2. two")

notes.each_with_index { |body, i|
  tester.verify_page_number(i+1, notes.length)
  tester.verify_note(body)
  tester.flick_note_left
}

puts "Checking that placeholder note past end is correct..."
tester.verify_empty
tester.verify_next_note(notes[0])

tester.kill
