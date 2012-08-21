#DESCRIPTION: Single note is in ring with empty note
require File.expand_path(File.join(File.dirname( __FILE__ ), 'qmlnotes_tester'))

tester = QmlnotesTester.new

body = "Test note 1\n"

tester.verify_empty
tester.write_note(body)
tester.verify_note(body)

[:Left, :Right].each do |dir|
  tester.flick_note(dir)
  tester.verify_empty

  tester.flick_note(dir)
  tester.verify_note(body)

  tester.flick_note(dir)
  tester.verify_empty

  tester.flick_note(dir)
  tester.verify_note(body)
end

tester.kill
