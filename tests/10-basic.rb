#!/usr/bin/ruby

require 'test/unit'
require 'qmlnotes_tester'

class TC_Qmlnotes_Basic < Test::Unit::TestCase

    def setup
        @tester = QmlnotesTester.new
    end

    def teardown
        if @test_passed == false
            @tester.kill
        end
    end

    def test_initial_empty_pages
        @tester.verify_empty
        @tester.flick_note_left
        @tester.verify_empty
        @tester.flick_note_right
        @tester.flick_note_right
        @tester.verify_empty
    end

end
