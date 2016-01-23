#!/usr/bin/env ruby

require "rubygems"
require "nokogiri"

tmux = "/usr/local/bin/tmux"
windows = `#{tmux} list-windows`.lines.map do |line|
  if line =~ /^\d+:([^(]*)\(/
    $1.strip.sub(/\s?[-*]?Z?$/, '')
  end
end

builder = Nokogiri::XML::Builder.new do |xml|
  xml.items {
    windows.each_with_index {|window, i|
      window_index = i+1
      xml.item(arg: window_index, uid: window_index) {
        xml.title "#{window_index}. #{window}"
        panes = `#{tmux} list-panes -t #{window_index} |wc -l`.strip
        xml.subtitle "#{panes} panes"
      }
    }
  }
end

puts builder.to_xml

