#!/usr/bin/env ruby

require "rubygems"
require "nokogiri"

# There are 10 windows, represented by 1,...,9,0
# First digit represents window id
# Optional second digit represents pane id (start from 1)
if ARGV[0] =~ /^(\d)(\d)?$/
  window_arg = $1
  pane_arg   = $2
  ARGV.shift
end

command = ARGV

tmux = "/usr/local/bin/tmux"
windows = `#{tmux} list-windows`.lines.map do |line|
  if line =~ /^\d+:([^(]*)\(/
    $1.strip.sub(/\s?[-*]?Z?$/, '')
  end
end

builder = Nokogiri::XML::Builder.new do |xml|
  xml.items {
    if pane_arg

    elsif window_arg
      window_index = window_arg == '0' ? 10 : window_arg.to_i
      panes = `#{tmux} list-panes -t #{window_index} |wc -l`.to_i
      panes.times {|i|
        xml.item(arg: window_index, uid: window_index) {
          xml.title "Window #{window_index}. #{windows[window_index - 1]} -> Pane #{i + 1}"
        }
      }
    else
      windows.each_with_index {|window, i|
        window_index = i+1

        xml.item(arg: window_index, uid: window_index) {
          xml.title "Window #{window_index}. #{window}"
          panes = `#{tmux} list-panes -t #{window_index} |wc -l`.strip
          xml.subtitle "#{panes} panes"
        }
      }
    end
  }
end

puts builder.to_xml

