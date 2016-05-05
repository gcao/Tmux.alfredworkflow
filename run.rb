#!/usr/bin/env ruby

require './tmux'

if ARGV.length > 0
  if ARGV[0] =~ /^(\d)(\.(\d))?$/
    ARGV.shift
    window, pane, rest = $1, $3, $4
    cmd = "#{TMUX} select-window -t #{window}"
    cmd += "; #{TMUX} select-pane -t:.#{pane.to_i - 1}" if pane
    puts cmd
    system cmd

    target = "-t:#{window}"
    target += ".#{pane}" if pane
  end

  if ARGV.length > 0
    cmd = "#{TMUX} send-keys #{target} \"#{ARGV.join(' ')}\" C-m"
    puts cmd
    system cmd
  end
end

