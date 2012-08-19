#!/usr/bin/ruby

require 'tdriver'
include TDriverVerify
include TDriverReportTestUnit

class QmlnotesTester

  def initialize
    @sut = TDriver.sut(:sut_qt)
    @app = @sut.run(:name => 'qmlnotes', :restart_if_running => true,
                    :arguments => '-fullscreen,-testability')
    @timeout = 30
  end

  def kill
    @app.close(:force_kill => true, :check_process => true)
  end

  def restart
    @app.close(:check_process => true)
    @app = @sut.run(:name => 'qmlnotes',
                    :arguments => '-fullscreen,-testability')
  end

  def verify_empty
    verify(@timeout, "expected empty Note page") { @app.Note(:text => '') }
  end

  def _flick_note(direction, adj)
    old_index = @app.NoteRing.ListView['currentIndex']
    @app.NoteRing.ListView.flick(:direction => direction)
    new_index = (old_index.to_i + adj).to_s
    verify(@timeout,
      "Expected flick to move note #{new_index} into view") { 
      @app.NoteRing.ListView.Note(:index => new_index,
                                  :visibleOnScreen => 'true')
    }
    verify(@timeout,
      "Expected flick to move note ring to note #{new_index}") {
      # The ListView will wrap around if it hits the edges, but still
      # it should hit new_index temporarily before being adjusted.
      @app.NoteRing.ListView(:currentIndex => new_index)
    }
  end

  def flick_note_left
    _flick_note(:Left, -1)
  end

  def flick_note_right
    _flick_note(:Right, +1)
  end

end
