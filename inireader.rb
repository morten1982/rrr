class IniReader

  attr_reader :content

  def initialize(filename)
    @filename = filename
    @data = ""
    @key = ""
    @mate = []
    @gnome = []
    @kde = []
    @xterm = []
    @mac = []
    @windows = []
    @system = ""
    @tabwidth = ""
    @font = ""
    @size = ""
    open_file(filename)
  end
  
  def open_file(filename)
    begin
      @data = ""
      f = File.open(filename, "r") 
      f.each_line do |line|
        @data += line 
      end
      f.close
    rescue => e
      p e.message
      return
    end
  end
  
  def parse
    @data.each_line do |line|
      if line.start_with?("[")
        @key = line.gsub!("[]", "")
        next
      elsif line == "\n"
        @key = ""
        next
      else
        x = line.split("=")
        k = x[0]
        v = x[1]
        if @key == "" then next end
        y = case k
            when "mate "
              @mate << v.lstrip.chop!
            when "gnome "
              @gnome << v.lstrip.chop!
            when "kde "
              @kde << v.lstrip.chop!
            when "xterm "
              @xterm << v.lstrip.chop!
            when "mac "
              @mac << v.lstrip.chop!
            when "windows "
              @windows << v.lstrip.chop!
            when "tabwidth "
              @tabwidth = v.lstrip
            when "font "
              @font = v.lstrip.chop!
            when "size "
              @size = v.lstrip.chop!
            when "system "
              @system = v.lstrip.chop!
        end
      end
    end
  end
  
  def get_system
    @system
  end
  
  def get_tabwidth
    @tabwidth
  end
  
  def get_font
    @font
  end
  
  def get_size
    @size
  end
  
  def set_system(name)
    @system = name
    new_content = ""
    @data.each_line do |line|
      if line.start_with?("system")
        new_content += "system = " + name + "\n"
      else
        new_content += line
      end
    end
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    f = File.open(filename, "w")
    new_content.each_line do |line|
      f.write(line)
    end
    f.close
  end
  
  def set_ini_file(system, run, terminal, interpreter, tabwidth, size)
    new_content = ""
    indent = 0
    @data.each_line do |line|
      if line.start_with?(system)
        if indent == 0
          new_content += system + " = " + run + "\n"
          indent += 1
        elsif indent == 1
          new_content += system + " = " + terminal + "\n"
          indent += 1
        elsif indent == 2
          new_content += system + " = " + interpreter + "\n"
          indent += 1
        else
          next
        end
      elsif line.start_with?("tabwidth")
        new_content += "tabwidth = " + tabwidth + "\n"
      elsif line.start_with?("size")
        if size.to_i <= 64 && size.to_i >= 6
          new_content += "size = " + size + "\n"
        else
          new_content += "size = " + "12" + "\n"
        end
      else
        new_content += line
      end
    end
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    f = File.open(filename, "w")
    new_content.each_line do |line|
      f.write(line)
    end
    f.close
  end
  
  def get_content(system)
    if system == "mate"
      @content = [@mate[0], @mate[1], @mate[2]]
    elsif system == "gnome"
      @content = [@gnome[0], @gnome[1], @gnome[2]]
    elsif system == "kde"
      @content = [@kde[0], @kde[1], @kde[2]]
    elsif system == "xterm"
      @content = [@xterm[0], @xterm[1], @xterm[2]]
    elsif system == "windows"
      @content = [@windows[0], @windows[1], @windows[2]]
    elsif system == "mac"
      @content = [@mac[0], @mac[1], @mac[2]]
    else
      @content = []
    end
  end
end

if __FILE__ == $0
  ini = IniReader.new("rrr.ini")
  ini.parse
  system = ini.get_system
  content = ini.get_content(system)
  p content
  #ini.set_system("mate")
end
  