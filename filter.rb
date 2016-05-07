require "rubygems"
require "nokogiri"
require "./tmux"

# There are 10 windows, represented by 1,...,9,0
# First digit represents window id
# Optional second digit represents pane id (start from 1)
if ARGV[0] =~ /^(\d)(\d)?(.*)$/
  window_arg = $1
  pane_arg   = $2
  command    = $3
elsif ARGV[0] =~ /^([^\d]+)(\d)?(.*)$/
  window_arg = $1
  pane_arg   = $2
  command    = $3
else
  command = ARGV[0]
end

builder = Nokogiri::XML::Builder.new do |xml|
  xml.items {
    if pane_arg
      window = TmuxWindow.find(window_arg)
      pane = window.panes[pane_arg.to_i - 1]
      arg = "#{pane.to_alfred_arg} #{command}"
      xml.item(arg: arg, uid: pane.to_alfred_uid) {
        xml.title pane.to_alfred_title
      }
    elsif window_arg
      found = TmuxWindow.find(window_arg)
      if found.is_a? TmuxWindow
        found.panes.each {|pane|
          arg = "#{pane.to_alfred_arg} #{command}"
          xml.item(arg: arg, uid: pane.to_alfred_uid) {
            xml.title pane.to_alfred_title
          }
        }
      else
        found.each {|window|
          arg = "#{window.to_alfred_arg} #{command}"
          xml.item(arg: arg, uid: window.index) {
            xml.title window.to_alfred_title
            xml.subtitle window.panes_str
          }
        }
      end
    else
      TmuxWindow.all.each {|window|
        arg = "#{window.to_alfred_arg} #{command}"
        xml.item(arg: arg, uid: window.index) {
          xml.title window.to_alfred_title
          xml.subtitle window.panes_str
        }
      }
    end
  }
end

puts builder.to_xml

