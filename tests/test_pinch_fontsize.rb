#DESCRIPTION: Font size can be pinched and zoomed
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

notes = [
  "Test font size\nSecond line\n",
  "Test second note font size\nSecond line\n"
]

puts "Creating two notes..."
tester.verify_empty
tester.write_note(notes[0])
tester.verify_note(notes[0])
tester.flick_note_left
tester.write_note(notes[1])
tester.verify_note(notes[1])

puts "Making font smaller..."
old_font_size = tester.get_font_size
tester.note_zoom(:out, 100)
new_font_size = tester.get_font_size
unless new_font_size < old_font_size
  puts "Font size did not become smaller! #{old_font_size} to #{new_font_size}"
  exit 1
end
tester.flick_note_right
tester.verify_note(notes[0])
unless new_font_size == tester.get_font_size
  puts "Font size change did not affect both notes"
  exit 1
end

puts "Making font bigger..."
old_font_size = tester.get_font_size
tester.note_zoom(:in, 200)
new_font_size = tester.get_font_size
unless new_font_size > old_font_size
  puts "Font size did not become bigger! #{old_font_size} to #{new_font_size}"
  exit 1
end
tester.flick_note_left
tester.verify_note(notes[1])
unless new_font_size == tester.get_font_size
  puts "Font size change did not affect both notes"
  exit 1
end

tester.kill
