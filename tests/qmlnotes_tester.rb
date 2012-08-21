require 'tdriver'
include TDriverVerify

class QmlnotesTester

  def initialize
    @sut = TDriver.sut(:sut_qt)
    @app = @sut.run(:name => 'qmlnotes', :restart_if_running => true,
                    :arguments => '-fullscreen,-testability')
    @timeout = nil
  end

  def kill
    @app.close(:force_kill => true, :check_process => true)
  end

  def restart
    @app.close(:check_process => true)
    @app = @sut.run(:name => 'qmlnotes',
                    :arguments => '-fullscreen,-testability')
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

  def flick_note(direction)
    # Even if the currentIndex gets reset to its original value (which can
    # happen if it wraps around a size-1 ring), it should at least briefly
    # take on a new value during the flick.
    @app.NoteRing.QDeclarativeListView.verify_signal(3, 'currentIndexChanged()',
        "Expected current index to change after flick") {
      @app.NoteRing.QDeclarativeListView.gesture(direction, 0.5, 300,
          :use_tap_screen => true)
    }
  end

  def flick_note_left
    flick_note(:Left)
  end

  def flick_note_right
    flick_note(:Right)
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
        when '.' then seq.append!(:kPeriod)
        else raise ArgumentError, "write_note cannot type '#{c}'"
      end
    end
    _current_note.press_key(seq)
  end

end
