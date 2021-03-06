require './tmux'

if ARGV.empty?
  puts <<-USAGE
Usage:
  # Run 'ls' in active pane of first window
  ruby #{__FILE__} 1 ls
  # Run 'ls -l' in first pane of first window and make the first pane active
  ruby #{__FILE__} 1.1 ls -l
  # Run 'ls' in active pane of active window
  ruby #{__FILE__} ls
  # Rename window
  ruby #{__FILE__} 1: Test
  USAGE
  exit 0
end

if ARGV[0] =~ /^(\d+):$/
  ARGV.shift
  window = $1
  cmd = "#{Tmux::PATH} rename-window -t "
  cmd += window.to_i == 0 ? '10' : window
  cmd += ' "' + ARGV.join(" ") + ' "'
  puts cmd
  system cmd
  exit
elsif ARGV[0] =~ /^(\d+)(\.(\d))?$/
  ARGV.shift
  window, pane = $1, $3
  cmd = "#{Tmux::PATH} select-window -t "
  cmd += window.to_i == 0 ? '10' : window
  cmd += "; #{Tmux::PATH} select-pane -t:.#{pane.to_i - 1}" if pane
  puts cmd
  system cmd

  target = "-t:#{window}"
  target += ".#{pane.to_i - 1}" if pane
end

if ['re', 'restart'].include? ARGV[0]
  system "#{Tmux::PATH} send-keys #{target} C-c '!!' C-m C-m"
elsif ARGV.length > 0
  system "#{Tmux::PATH} send-keys #{target} \"#{ARGV.join(' ')}\" C-m"
end

