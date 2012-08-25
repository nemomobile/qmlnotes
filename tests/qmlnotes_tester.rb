require 'tdriver'
include TDriverVerify

class QmlnotesTester

  def initialize
    @sut = TDriver.sut(:sut_qt)
    @app = @sut.run(:name => 'qmlnotes', :restart_if_running => true,
                    :arguments => '-fullscreen,-testability')
    @timeout = nil
    @next_wake = Time.now - 1
    wake_display
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

  def _horiz_overlap(a, b)
    al = a['x'].to_i
    ar = a['x'].to_i + a['width'].to_i
    bl = b['x'].to_i
    br = b['x'].to_i + b['width'].to_i
    # note that the 'r' values are just past the end of the object
    return (al >= bl && al < br) || (ar > bl && ar <= br)
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

  def flick_note(direction)
    wake_display
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
    @app.Button(attrs).verify_signal(3, 'clicked()',
        "Expected clicked signal after tap") {
      @app.Button(attrs).tap
    }
  end

  def tap_menu(text)
    wake_display
    close_keyboard  # make sure toolbar is visible
    tap_tool('toolbarMenuIcon')
    @app.MenuItem(:text => text).verify_signal(3, 'clicked()',
        "Expected clicked signal after menu tap") {
      @app.MenuItem(:text => text).tap
    }
  end

end
