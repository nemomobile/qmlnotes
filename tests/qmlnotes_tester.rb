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

  def verify_empty
    verify_equal('', @timeout, "expected empty Note page") {
      @app.Note(:x => @app.NoteRing['x'], :y => @app.NoteRing['y'])['text']
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

  def _flick_note(direction)
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
    _flick_note(:Left)
  end

  def flick_note_right
    _flick_note(:Right)
  end

end
