require "rubygems"
require "nokogiri"
require "./tmux"

# There are 12 windows, represented by 1,...,9,0,-,=
# First digit represents window id
# Optional second digit represents pane id (start from 1)
if ARGV[0] =~ /^(\d|[,;:\-=])(\d|[,;:])?(.*)$/
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
      if pane_arg == ':'
        window = Tmux::Window.find(window_arg)
        arg = "#{window.to_alfred_arg}: #{command}"
        xml.item(arg: arg) do
          xml.title "#{window.index} #{window.name}: Rename"
        end
      else
        window = Tmux::Window.find(window_arg)
        pane = [',', ';'].include?(pane_arg) ? window.active_pane : window.panes[pane_arg.to_i - 1]
        arg = "#{pane.to_alfred_arg} #{command}"
        xml.item(arg: arg, uid: pane.to_alfred_uid, autocomplete: pane.to_alfred_autocomplete) do
          xml.title pane.to_alfred_title.gsub(/<[^>]+>/, '').gsub(' * $', '$').gsub('   $', '$')
        end
        pane.history.each do |entry|
          next if command and entry.command !~ /#{command.gsub(//, '.*')}/i
          xml.item(arg: entry.to_alfred_arg, uid: entry.to_alfred_arg) do
            xml.title entry.to_alfred_title
            xml.subtitle entry.to_alfred_subtitle
          end
        end
      end
    elsif window_arg
      found = Tmux::Window.find(window_arg)
      if found.is_a? Tmux::Window
        found.panes.each do |pane|
          arg = "#{pane.to_alfred_arg} #{command}"
          xml.item(arg: arg, uid: pane.to_alfred_uid, autocomplete: pane.to_alfred_autocomplete) do
            xml.title pane.to_alfred_title.gsub(/<[^>]+>/, '')
            xml.subtitle pane.to_alfred_subtitle
          end
        end

        arg = "#{found.to_alfred_arg}: #{command}"
        xml.item(arg: arg) do
          xml.title "#{found.index} #{found.name}: Rename"
        end
      else
        found.each do |window|
          arg = "#{window.to_alfred_arg} #{command}"
          xml.item(arg: arg, uid: window.to_alfred_uid, autocomplete: window.to_alfred_autocomplete) do
            xml.title window.to_alfred_title
            xml.subtitle window.to_alfred_subtitle
          end
        end
      end
    else
      windows = [Tmux::Window.active, Tmux::Window.last] + Tmux::Window.all.reject{|w| w.active? or w.last? }
      windows.each do |window|
        arg = "#{window.to_alfred_arg} #{command}"
        xml.item(arg: arg, uid: window.to_alfred_uid, autocomplete: window.to_alfred_autocomplete) do
          xml.title window.to_alfred_title
          # xml.subtitle window.to_alfred_subtitle
          # xml.icon 'test'
        end
      end
    end
  end
end

puts builder.to_xml

