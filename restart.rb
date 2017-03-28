require './tmux'

window = Tmux.active_window
pane   = window.active_pane
system "#{Tmux::PATH} send-keys #{window.index}.#{pane.index} C-c '!!' C-m C-m"
