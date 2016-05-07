# encoding: UTF-8

module Tmux
  PATH = ENV['TMUX_PATH'] || "/usr/local/bin/tmux"

  class Window
    attr :name
    attr :index
    def active?; @active; end
    def last?; @last; end

    def self.all
      @all ||= `#{PATH} list-windows`.lines.map do |line|
        new line
      end
    end

    def self.active
      all.select(&:active?).first
    end

    def self.last
      all.select(&:last?).first
    end

    # i is like 1,2,...,9,0 or part of window name
    def self.find i
      if i =~ /^0$/
        all[9]
      elsif i =~ /^\d$/
        all[i.to_i - 1]
      else
        found = all.select do |window|
          window.name =~ /#{i.gsub(//, '.*')}/i
        end

        if found.size == 1
          found[0]
        else
          found
        end
      end
    end

    #1: Z (3 panes) [204x67] [layout cc9f,204x67,0,0,2] @1
    #2: Servers   (4 panes) [204x67] [layout 3710,204x67,0,0{129x67,0,0[129x32,0,0,4,129x34,0,33,5],74x67,130,0[74x32,130,0,6,74x34,130,33,7]}] @2
    #3: AdminV2 - (3 panes) [204x67] [layout 0ab1,204x67,0,0{129x67,0,0,8,74x67,130,0[74x32,130,0,9,74x34,130,33,10]}] @3
    #4: HDAP   (3 panes) [204x67] [layout 8deb,204x67,0,0{129x67,0,0,11,74x67,130,0[74x34,130,0,12,74x32,130,35,13]}] @4
    #5: Tmux Workflow * (3 panes) [204x67] [layout 0e01,204x67,0,0{129x67,0,0,14,74x67,130,0[74x34,130,0,15,74x32,130,35,16]}] @5 (active)
    #6: SSU Redesign Z (3 panes) [204x67] [layout 6686,204x67,0,0,17] @6
    #7: Misc Z (3 panes) [204x67] [layout e681,204x67,0,0,22] @7
    #8:   (3 panes) [204x67] [layout ce00,204x67,0,0{129x67,0,0,23,74x67,130,0[74x34,130,0,24,74x32,130,35,25]}] @8
    #9: Agent   (3 panes) [204x67] [layout 4e1a,204x67,0,0{129x67,0,0,26,74x67,130,0[74x34,130,0,27,74x32,130,35,28]}] @9
    def initialize representation
      representation =~ /^(\d+):\s+([^(]+)?\s+\(/
      @index  = $1
      @name   = $2.to_s.strip
      @active = @name =~ /\*Z?$/
      @last   = @name =~ /-Z?$/
      @name   = @name.sub(/Z$/, '').sub(/-$/, '').sub(/\*$/, '')
    end

    def panes
      @panes ||= `#{PATH} list-panes -t #{@index}`.lines.map {|line|
        Pane.new self, line
      }
    end

    def to_alfred_arg
      @index.to_i % 10
    end

    def to_alfred_uid
      rand
    end

    def to_alfred_title
      if @active
        #"<#{@index}> #{@name}"
        "#{@index}. <ACTIVE> #{@name}"
      elsif @last
        "#{@index}. <LAST> #{@name}"
      else
        "#{@index}. #{@name}"
      end
    end

    def to_alfred_subtitle
      #"#{@panes_str}: #{panes.map{|pane| "<#{pane.index}> #{pane.process}"}.join('   ') }"
      panes.map {|pane|
        s = pane.index.to_s
        if pane.active
          s = "<#{s}> "
        else
          s += ". "
        end
        s + pane.process
      }.join('    ')
    end

  end

  class Pane
    attr :index
    attr :active

    #0: [129x67] [history 6889/20000, 1466530 bytes] %1
    #1: [204x67] [history 138/20000, 80566 bytes] %2 (active)
    #2: [74x34] [history 595/20000, 499310 bytes] %3
    def initialize parent, representation
      @parent = parent
      representation =~ /^(\d)+:[^\(]*(\(active\))?\s*$/
      @index  = $1.to_i + 1
      @active = !!$2
    end

    def buffer
      `#{PATH} capture-pane -t:#{@parent.index}.#{@index - 1} -p -S -200`.encode('utf-8', 'utf-8').strip.lines
    end

    def process
      #http://stackoverflow.com/questions/9560768/how-do-you-use-unicode-characters-within-a-regular-expression-in-ruby
      # \uE0B0 = 
      case buffer.last.encode('utf-8', 'utf-8')
      when /(^ [A-Z]+ \uE0B0)|\uE0A1/ then "vim"
      when / ([^\uE0B0]*[\/~][^\uE0B0]*) \uE0B0/    then "#{$1} $"
      when /\$( |$)/                  then buffer.last
      else
        if buffer[-2] && buffer[-2].encode('utf-8', 'utf-8') =~ /(^ [A-Z]+ \uE0B0)|\uE0A1/
          "vim"
        else
          "Other long-running process"
        end
      end
    end

    def to_alfred_title
      title = "#{@parent.to_alfred_title}  => Pane #{@index}"
      if @active
        title += " * "
      else
        title += "   "
      end
      "#{title} #{process}"
    end

    def to_alfred_arg
      "#{@parent.to_alfred_arg}.#{@index}"
    end

    def to_alfred_uid
      "#{@parent.index}.#{@index}"
    end
  end

end

