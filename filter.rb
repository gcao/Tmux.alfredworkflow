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
  xml.items do
    if pane_arg
      window = Tmux::Window.find(window_arg)
      pane = window.panes[pane_arg.to_i - 1]
      arg = "#{pane.to_alfred_arg} #{command}"
      xml.item(arg: arg, uid: pane.to_alfred_uid) do
        xml.title pane.to_alfred_title.gsub(/<[^>]+>/, '')
      end
      pane.history.each do |entry|
        next if command and entry.command !~ /#{command.gsub(//, '.*')}/i
        xml.item(arg: "#{pane.to_alfred_arg} #{entry.command}", uid: rand) do
          xml.title entry.to_alfred_title
        end
      end
    elsif window_arg
      found = Tmux::Window.find(window_arg)
      if found.is_a? Tmux::Window
        found.panes.each do |pane|
          arg = "#{pane.to_alfred_arg} #{command}"
          xml.item(arg: arg, uid: pane.to_alfred_uid) do
            xml.title pane.to_alfred_title.gsub(/<[^>]+>/, '')
          end
        end
      else
        found.each do |window|
          arg = "#{window.to_alfred_arg} #{command}"
          xml.item(arg: arg, uid: window.to_alfred_uid) do
            xml.title window.to_alfred_title
            xml.subtitle window.to_alfred_subtitle
          end
        end
      end
    else
      windows = [Tmux::Window.active, Tmux::Window.last] + Tmux::Window.all
      windows.each do |window|
        arg = "#{window.to_alfred_arg} #{command}"
        xml.item(arg: arg, uid: window.to_alfred_uid) do
          xml.title window.to_alfred_title
          xml.subtitle window.to_alfred_subtitle
        end
      end
    end
  end
end

puts builder.to_xml

