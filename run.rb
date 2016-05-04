#!/usr/bin/env ruby

if ARGV.length > 0
  if ARGV[0] =~ /^(\d)(\.(\d))?$/
    ARGV.shift
    window, pane = $1, $3
    cmd = "tmux select-window -t #{window}"
    cmd += "; tmux select-pane -t:.#{pane.to_i - 1}" if pane
    puts cmd
    system cmd
  end

  system "tmux send-keys -t 2 \"#{ARGV.join(' ')}\" C-m"
end

