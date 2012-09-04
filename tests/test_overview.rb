#DESCRIPTION: Notes app overview mode
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

notes = [
  "'Twas brillig, and the slithy toves\n",
  "Did gyre and gimble in the wabe;",
  "All mimsy were the borogoves,\n\nAnd the mome raths outgrabe."
]

tester.verify_empty

puts "Testing empty overview..."
tester.tap_tool('toolbarOverviewIcon')
tester.verify_label("No notes yet")
tester.tap_button("New note")
tester.verify_empty

puts "Creating notes..."
notes.each { |body|
  tester.write_note(body)
  tester.verify_note(body)
  tester.flick_note_left
}

puts "Testing overview jump..."
notes.each_with_index { |body, i|
  tester.tap_tool('toolbarOverviewIcon')
  title = body.split("\n")[0]
  tester.tap_overview("#{i+1}. #{title}")
  tester.verify_note(body)
}

puts "Testing jump to new note..."
tester.tap_tool('toolbarOverviewIcon')
tester.tap_button("New note")
tester.verify_empty

tester.kill
