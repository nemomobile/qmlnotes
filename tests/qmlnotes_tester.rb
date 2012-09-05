require 'set'
require 'tdriver'
include TDriverVerify

# The purpose of this class is to encapsulate knowledge about the
# structure of the QMLNotes UI and the TDriver commands so that
# the test cases can be written in terms of user actions (flick,
# drag, tap) and user observables ("what is the text of the visible note?")

class QmlnotesTester

  def initialize
    @sut = TDriver.sut(:sut_qt)
    @app = @sut.run(:name => 'qmlnotes', :restart_if_running => true,
                    :arguments => '-fullscreen,-testability')
    @timeout = nil
    @next_wake = Time.now - 1
    wake_display
    @last_object_finder = Proc.new { nil }
  end

  def kill
    @app.close(:force_kill => true, :check_process => true)
  end

  def restart
    @app.close(:check_process => true)
    @app = @sut.run(:name => 'qmlnotes',
                    :arguments => '-fullscreen,-testability')
  end

  def wake_display
    # Unlock the screen before trying gestures, but rate-limit it a bit
    if Time.now >= @next_wake
      @next_wake = Time.now + 100 
      # Note: the screen unlock is not done with mcetool because the dbus
      # policy on Nemo restricts it to root.
      ok = system("dbus-send", "--print-reply", "--system",
         "--dest=com.nokia.mce", "/nokia/mce/request",
         "com.nokia.mce.request.req_tklock_mode_change", "string:unlocked")
      if (!ok)
        puts "Failed to unlock display"
        exit 1
      end
    end
  end

  def create_notes_fixture(notes)
    # Create notes efficiently by bypassing the UI actions.
    # This cannot be used to test note creation! It just helps
    # set things up quickly for other tests.
    index = @app.NoteRing.QDeclarativeListView['lastNote'].to_i + 1
    notes.each { |body|
      @app.NoteRing.set_attribute(:currentIndex, index)
      @app.Note(:index => index.to_s).set_attribute(:text, body)
      index += 1
    }
  end

  def _horiz_overlap(a, b)
    al = a['x'].to_i
    ar = a['x'].to_i + a['width'].to_i
    bl = b['x'].to_i
    br = b['x'].to_i + b['width'].to_i
    # note that the 'r' values are just past the end of the object
    return (al >= bl && al < br) || (ar > bl && ar <= br)
  end

  def _wait_to_settle
    # Wait for a value to stop changing. Call it with a block.
    # Can be handy to synchronize between interactions
    prev_value = yield
    stability = 0
    timeout = Time.now + 30
    while Time.now < timeout do
      sleep 0.1
      new_value = yield
      if new_value == prev_value
        stability += 1
      else
        stability = 0
      end
      return if stability == 2
      prev_value = new_value
    end
    puts "expected object to settle down"
    exit 1
  end

  def _current_note
    @app.Note(:x => @app.NoteRing['x'], :y => @app.NoteRing['y'])
  end

  def _toolbar
    # Adventures in TDriver: the ToolBar shows up again inside its own
    # BorderImage. Probably a confusion between the Qt and QML notions
    # of "children". So just doing @app.ToolBar makes TDriver complain
    # that there are two candidates.
    @app.children(:type => 'ToolBar')[0]
  end

  def _last_object(&block)
    if block_given?
      @last_object_finder = block
    end
    @last_object_finder.call
  end

  def verify_empty
    verify_equal('', @timeout, "expected empty Note page") {
      _current_note['text']
    }
  end

  def verify_note(body)
    verify_equal(body, @timeout, "did not find expected note text") {
      _current_note['text']
    }
  end

  def verify_next_note(body)
    # This still counts as a user observable because the user can see
    # it when dragging or flicking, even if the NoteRing logic then
    # moves the index to the other end of the ring (which prevents it
    # from being observed through verify_note)
    _current_note.drag(:Left, 50, :Left, :use_tap_screen => true)
    index = (_current_note['index'].to_i + 1).to_s
    verify_equal(body, @timeout,
                 "did not find expected text in note #{index}") {
      @app.Note(:index => index)['text']
    }
  end

  def verify_index(index)
    verify(@timeout, "expected current note #{index}") {
      @app.NoteRing.QDeclarativeListView(:currentIndex => index.to_s)
    }
    verify(@timeout, "expected current note to be in view") {
      listview = @app.NoteRing.QDeclarativeListView
      _horiz_overlap(listview.Note(:index => index.to_s), listview)
    }
  end

  def verify_page_number(page, maxpage)
    # The page number is the only Label in the toolbar.
    # If that ever changes, it probably needs an objectName or something
    # so that this function can still find it.
    if page.nil?
      verify(@timeout, "Expected empty page number") {
        _toolbar.find(:objectName => 'toolbarPageNumber', :text => "")
      }
    else
      expected = "#{page}/#{maxpage}"
      verify_equal(expected, @timeout, "Expected page #{expected}") {
        _toolbar.find(:objectName => 'toolbarPageNumber')['text']
      }
    end
  end

  def verify_label(text)
    verify { @app.Label(:text => text, :visible => 'true',
                        :visibleOnScreen => 'true') }
  end

  def verify_menu_enabled(text)
    verify_equal('true', @timeout, "Expected #{text} to be enabled") {
      @app.MenuItem(:text => text)['enabled']
    }
  end

  def verify_menu_disabled(text)
    verify_equal('false', @timeout, "Expected #{text} to be disabled") {
      @app.MenuItem(:text => text)['enabled']
    }
  end

  def verify_overview(titles)
    entries = nil
    verify_equal(titles.length) {
      entries = @app.children(:objectName => 'overviewbutton')
      entries.length
    }
    entries.sort_by! { |e| e['y'].to_i }
    titles.each_with_index { |title, i|
      if title.nil?
        verify_equal('0') { entries[i]['opacity'] }
      else
        verify_equal(title) { entries[i]['text'] }
      end
    }
  end

  def flick_note(direction)
    wake_display
    # When testing on a VM (fast) there's often a problem with flicks
    # starting too soon after the previous action.
    sleep 1
    width = @app.NoteRing['width'].to_i
    # Even if the currentIndex gets reset to its original value (which can
    # happen if it wraps around a size-1 ring), it should at least briefly
    # take on a new value during the flick.
    @app.NoteRing.QDeclarativeListView.verify_signal(3, 'currentIndexChanged()',
        "Expected current index to change after flick") {
      @app.NoteRing.QDeclarativeListView.gesture(direction, 0.5, width/3,
          :use_tap_screen => true)
    }
  end

  def flick_note_left
    flick_note(:Left)
  end

  def flick_note_right
    flick_note(:Right)
  end

  def close_keyboard
    _current_note.QDeclarativeTextEdit.call_method('closeSoftwareInputPanel()')
    _wait_to_settle { _current_note['height'] }
  end

  def write_note(body)
    _current_note.tap
    verify_equal("true", @timeout,
      "Expected current note to get active focus") {
      _current_note.QDeclarativeTextEdit['activeFocus']
    }
    seq = MobyCommand::KeySequence.new
    body.each_char do |c|
      case c
        when /[a-z0-9]/ then seq.append!("k#{c.upcase}".to_sym)
        when /[A-Z]/
          seq.append!(:kShift, :KeyDown)
          seq.append!("k#{c}".to_sym)
          seq.append!(:kShift, :KeyUp)
        when ' ' then seq.append!(:kSpace)
        when "\n" then seq.append!(:kEnter)
        when '?' then seq.append!(:kQuestion)
        when '.' then seq.append!(:kPeriod)
        when ',' then seq.append!(:kComma)
        when ';' then seq.append!(:kSemicolon)
        when "'" then seq.append!(:kApostrophe)
        else raise ArgumentError, "write_note cannot type '#{c}'"
      end
    end
    _current_note.press_key(seq)
    close_keyboard
  end

  def note_zoom(type, distance)
    # Terminology:
    # type :in means zoom in so fingers move apart
    # type :out means zoom out so fingers move together

    _current_note.pinch_zoom(:type => type, :speed => 1,
         :distance_1 => distance, :distance_2 => distance,
         :differential => 100, :direction => 90)
  end

  def get_font_size
    # The font attribute looks like "Sans Serif,24,-1,5,50,0,0,0,0,0"
    _current_note.QDeclarativeTextEdit['font'].split(',')[1].to_f
  end

  def tap_tool(name)
    wake_display
    close_keyboard  # make sure toolbar is visible
    attrs = {:objectName => name, :visibleOnScreen => 'true'}
    _toolbar.ToolIcon(attrs).verify_signal(3, 'clicked()',
        "Expected clicked signal after tap") {
      _toolbar.ToolIcon(attrs).tap
    }
  end

  def tap_button(text)
    wake_display
    attrs = {:text => text, :visibleOnScreen => 'true'}
    _wait_to_settle { @app.Button(attrs).attributes }
    @app.Button(attrs).verify_signal(3, 'clicked()',
        "Expected clicked signal after tap") {
      @app.Button(attrs).tap
    }
  end

  def tap_overview(text)
    wake_display
    # For some reason the Buttons in the overview list started
    # showing up as QDeclarativeLoader after they got the property
    # alias for 'pressed', so search for them by objectName instead of type.
    attrs = {:text => text, :objectName => 'overviewbutton'}
    _wait_to_settle { @app.find(attrs).attributes }
    @app.find(attrs).verify_signal(3, 'clicked()',
        "Expected clicked signal after tap") {
      @app.find(attrs).tap
    }
  end

  def tap_menu(text)
    wake_display
    close_keyboard  # make sure toolbar is visible
    tap_tool('toolbarMenuIcon')
    _wait_to_settle { @app.MenuItem(:text => text).attributes }
    @app.MenuItem(:text => text).verify_signal(3, 'clicked()',
        "Expected clicked signal after menu tap") {
      @app.MenuItem(:text => text).tap
    }
  end

  def overview_tap_down(text)
    wake_display
    attrs = {:text => text, :objectName => 'overviewbutton'}
    _wait_to_settle { @app.find(attrs).attributes }
    @app.find(attrs).tap_down
    _wait_to_settle { @app.find(:objectName => 'dragproxy')['y'] }
  end

  def overview_release
    wake_display
    # The button might be invisible by now and then we can't call tap_up
    # on it. Subsitute a button release somewhere else.
    @app.find(:objectName => 'overviewlist').tap_up
  end

  def overview_drag_down(text, heights)
    wake_display
    attrs = {:text => text, :objectName => 'overviewbutton'}
    button = @app.find(attrs)
    distance = heights * button['height'].to_i
    x = button['x_absolute'].to_i + button['width'].to_i / 2
    y = button['y_absolute'].to_i + button['height'].to_i / 2
    increment = button['height'].to_i / 3
    points = [{'x' => x, 'y' => y, 'interval' => 1}]
    duration = 1
    (heights*3).times { |i|
      points << {'x' => x, 'y' => (y + (i+1) * increment).to_i,
                 'interval' => 0.1}
      duration += 0.1
    }
    button.gesture_points(points, duration, {}, :use_tap_screen => true)
  end

end
