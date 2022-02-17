#!/usr/bin/env ruby

require 'fox16'
require 'set'
require_relative './codeeditor.rb'
require_relative './filebrowser.rb'
require_relative './widgets.rb'
require_relative './commands'
require_relative './codeview.rb'
require_relative './inireader.rb'
require_relative './settings.rb'

include Fox

require 'fox16/undolist'

class RRR < FXMainWindow
  attr_accessor :editor,
                :codecompletion,
                :codeview,
                :tab_list,
                :tabbook
  
  def initialize(app)
    super(app, "Rapid Ruby Recorder", :width => 1200, :height => 800)
    @tab_list = []
    setBackColor('#000000')
    init_ui
  end

  def init_ui
    ##
    # Icon
    ##
    @bigicon = load_icon("rrr.png")
    @smallicon = load_icon("rrr.png")
    # Application icons
    setIcon(@bigicon)
    setMiniIcon(@smallicon)
    
    ##
    # Tool bar
    ##
    toolbar = FXToolBar.new(self,
      LAYOUT_SIDE_TOP|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH|PACK_UNIFORM_HEIGHT)
    toolbar.setBackColor('#0b0b0b')
    
    ##
    # Tool-Buttons
    ##
    newIcon = load_icon("new.png")
    newButton = PicButton.new(toolbar, "&New", newIcon,
      self, 1, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    newButton.connect(SEL_COMMAND) { new }
    
    openIcon = load_icon("open.png")
    openButton = PicButton.new(toolbar, "&Open", openIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    openButton.connect(SEL_COMMAND) { open }

    saveIcon = load_icon("save.png")
    saveButton = PicButton.new(toolbar, "&Save", saveIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    saveButton.connect(SEL_COMMAND) { save }
    
    saveAsIcon = load_icon("saveAs.png")
    saveAsButton = PicButton.new(toolbar, "Save &As", saveAsIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    saveAsButton.connect(SEL_COMMAND) { saveAs }
    
    printIcon = load_icon("print.png")
    printButton = PicButton.new(toolbar, "To HTML", printIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    printButton.connect(SEL_COMMAND) { print_to_html }

    undoIcon = load_icon("undo.png")
    undoButton = PicButton.new(toolbar, "Undo", undoIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    undoButton.connect(SEL_COMMAND) { cmd_undo }

    redoIcon = load_icon("redo.png")
    redoButton = PicButton.new(toolbar, "Redo", redoIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    redoButton.connect(SEL_COMMAND) { cmd_redo }
    
    zoomInIcon = load_icon("zoomIn.png")
    zoomInButton = PicButton.new(toolbar, "", zoomInIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    zoomInButton.connect(SEL_COMMAND) { cmd_zoomIn }

    zoomOutIcon = load_icon("zoomOut.png")
    zoomOutButton = PicButton.new(toolbar, "", zoomOutIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    zoomOutButton.connect(SEL_COMMAND) { cmd_zoomOut }
    
    settingsIcon = load_icon("settings.png")
    settingsButton = PicButton.new(toolbar, "Settings", settingsIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    settingsButton.connect(SEL_COMMAND) { settings }

    rubyIcon = load_icon("ruby.png")
    rubyButton = PicButton.new(toolbar, "irb", rubyIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_LEFT))
    rubyButton.connect(SEL_COMMAND) { interpreter }    

    runIcon = load_icon("run.png")
    runButton = PicButton.new(toolbar, "Run", runIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_RIGHT))
    runButton.connect(SEL_COMMAND) { run }        

    terminalIcon = load_icon("terminal.png")
    terminalButton = PicButton.new(toolbar, "Terminal", terminalIcon,
      self, 0, (ICON_ABOVE_TEXT|BUTTON_TOOLBAR|FRAME_RAISED|
      LAYOUT_TOP|LAYOUT_RIGHT))
    terminalButton.connect(SEL_COMMAND) { terminal }
    
    ##
    # Layout for Filebrowser / Codebrowser \\ Editor
    ##
    @splitter = FXSplitter.new(self,
      LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @splitter.setBackColor('#0b0b0b')
    
    @second_splitter = FXSplitter.new(@splitter, SPLITTER_VERTICAL,
      0, 0, 230, 0)
    @second_splitter.setBackColor('#0b0b0b')
    
    browserframe = FXVerticalFrame.new(@second_splitter,
      FRAME_SUNKEN|LAYOUT_SIDE_TOP,
      0, 0, 0, 320, 0, 0, 0, 0)
    browserframe.setBackColor("#0c0c0c")

    searchframe = FXHorizontalFrame.new(browserframe)
    searchframe.setBackColor("#0c0c0c")
    @search_field = FXTextField.new(searchframe, 20,
      :opts => TEXTFIELD_NORMAL)
    @search_field.setBackColor('#054C53')
    #@search_field.setBackColor('#003300')
    searchButton = FXButton.new(searchframe, "Search")
    searchButton.setBackColor("#0c0c0c")
    #searchButton.setBackColor("#003300")
    searchButton.setTextColor("#ffffff")
    searchButton.connect(SEL_COMMAND) { search }

    @filebrowser = Filebrowser.new(browserframe, :opts => \
                                   TREELIST_SINGLESELECT|LAYOUT_FILL)
    

    codeviewframe = FXVerticalFrame.new(@second_splitter,
      FRAME_SUNKEN|LAYOUT_SIDE_BOTTOM,
      0, 0, 20, 320, 0, 0, 0, 0)
    codeviewframe.setBackColor("#0c0c0c")
    
    @codeview = Codeview.new(codeviewframe, editor=nil, :opts => \
                                   TREELIST_SINGLESELECT|LAYOUT_FILL)
    
    @codecompletion = FXLabel.new(codeviewframe, "---", :opts => \
                                   LAYOUT_CENTER_X)
    @codecompletion.font = FXFont.new(app, "Mono", 12)
    @codecompletion.setBackColor('#0b0b0b')
    @codecompletion.setTextColor('#008000')   
    reset_completion

    @tabbook = NoteBook.new(@splitter, rrr=self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @tabbook.connect(SEL_COMMAND) { tab_book_changed }
    init_tabbook
  end
  
  def init_tabbook
    tab = TabItem.new(@tabbook, "noname")
    tab.connect(SEL_RIGHTBUTTONPRESS) do |sender, sel, event|
      @tabbook.setCurrent(@tab_list.size-1) # last item in list
      tab_contextmenu(sender, sel, event)
    end
    FXVerticalFrame.new(@tabbook) do |vf|
      vf.setBackColor('#0b0b0b')
      editor = Codeeditor.new(vf, filename="noname", tab=tab, filebrowser=@filebrowser,
                             @rrr=self,
                             :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y| \
                              TEXT_AUTOSCROLL|TEXT_AUTOINDENT|TEXT_NO_TABS)
      @tab_list << [tab, editor]
      set_widgets(editor)
    end
  end
  
  ##
  # exchange data between widgets -> !!! <-
  ##
  def set_widgets(editor)
    @filebrowser.editor = editor 
    @filebrowser.rrr = self
    editor.filebrowser = @filebrowser 
    @editor = editor
    @editor.set_tab_text
    @editor.autocomplete_list = get_autocomplete_list
    @editor.completion_list = []
    @codeview.editor = @editor
    @codeview.init_tree
  end
  
  def tab_book_changed
    x = @tabbook.getCurrent
    editor = @tab_list[x][1]
    editor.undolist.clear
    editor.undolist.mark
    set_widgets(editor)
    change_directory(editor)
  end
  
  def change_directory(editor)
    p "filename: " + editor.filename
    complete_path = editor.filename
    if complete_path == "noname"
      path = Dir.pwd + "/"
    else
      path = File.dirname(editor.filename) + "/"
    end
    @filebrowser.change_dir(path)
  end

  def new
    tab = TabItem.new(@tabbook, "noname")
    tab.connect(SEL_RIGHTBUTTONPRESS) do |sender, sel, event|
      @tabbook.setCurrent(@tab_list.size-1) # last item in list
      tab_contextmenu(sender, sel, event)
    end
    #tab.connect(SEL_KEYPRESS) do |sender, sel, event|
    #  if event.state == 24 && event.code == 65364
    #    # alt + down
    #    @editor.setFocus
    #  end
    #end
    FXHorizontalFrame.new(@tabbook) do |hf|
      hf.setBackColor('#0b0b0b')
      editor = Codeeditor.new(hf, filename="noname",tab=tab, filebrowser=@filebrowser,
                             @rrr=self,
                             :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y| \
                              TEXT_AUTOSCROLL|TEXT_AUTOINDENT|TEXT_NO_TABS)

      @tab_list << [tab, editor]
      set_widgets(editor)
    end
    @tabbook.create # realize widgets
    @tabbook.recalc # mark parent layout dirty
    x = @tab_list.size                       
    @tabbook.setCurrent(x-1)
  end

  def open
    dialog = FXFileDialog.new(@editor, "Open File")
    if dialog.execute != 0
      file = dialog.filename
      if @editor.text != ""
        message = FXMessageBox.question(@editor, 
                                      MBOX_YES_NO,
                                      "Open File ?", 
                                      "Open file in current editor window?")
        if message == MBOX_CLICKED_NO
          return
        end
      end
      text = @editor.load_file(file)
      @editor.filename = file
      @editor.clear
      @editor.appendText(text)
      @editor.highlight_text
      @filebrowser.set_title
      set_widgets(@editor)
      @editor.on_focus
    end
  end
  
  def save
    filename = @editor.filename
    #puts "filename from save: " + filename
    if filename == "noname"
      saveAs
    else
      @editor.save_file(filename)
      title = getTitle
      set_widgets(@editor)
      file = @editor.get_name_of_file
      @editor.change_tab_text(file)
    end
    @editor.setFocus()
  end
  
  def saveAs
    dialog = FXFileDialog.new(@editor, "Save As")
    if dialog.execute != 0
      file = dialog.filename
      @editor.filename = file
      setTitle(file)
      save
    end
  end
  
  def print_to_html
    if @editor.filename == "noname"
      message = FXMessageBox.error(@rrr, MBOX_OK, "Error", "No filename!\n\n" + 
                                   "Save file first !")
      return
    end
    
    filename = File.basename(@editor.filename) + ".html"
  
    text = @editor.text
    output = "<head>" + filename + "</head>\n"
    output += "<body>\n"
    output += "<pre><code>\n"
    output += text 
    output += "</pre></code>\n"
    output += "</body>"
    
    path = Dir.pwd
    complete_path = path + "/" + filename
    
    f = File.open(filename, "w")
    output.each_line do |line|
      f.write(line)
    end
    f.close
    @editor.setFocus
    
    link = complete_path
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      system "start #{link}"
    elsif RbConfig::CONFIG['host_os'] =~ /darwin/
      system "open #{link}"
    elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
      system "xdg-open #{link}"
    end
  
  end
  
  def cmd_undo
    @editor.undo
    @codeview.init_tree
    return
  end
  
  def cmd_redo
    @editor.redo
    @codeview.init_tree
    return
  end
  
  def cmd_zoomIn
    if @editor.font_size >= 64
      @editor.setFocus
      return
    else
      @editor.zoomIn
      @editor.setFocus
      return
    end
  end
  
  def cmd_zoomOut
    if @editor.font_size <= 2
      @editor.setFocus
      return
    else
      @editor.zoomOut
      @editor.setFocus
      return
    end
  end
  
  def settings
    dialog = SettingsDialog.new(self).execute
    return 1
  end
  
  def interpreter
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    ini = IniReader.new(filename)
    ini.parse
    system = ini.get_system
    run, terminal, interpreter = ini.get_content(system)
    thr = Thread.new { %x(#{interpreter}) }
    #%x(#{interpreter})
  end
  
  def search
    @codecompletion.text = "---" 
    pos = @editor.getCursorPos
    text = @search_field.text
    x = @editor.findText(text, pos,
                        :flags => SEARCH_WRAP|SEARCH_EXACT)
    if x
      _beg = x[0][0]
      _end = x[1][0]
      @editor.setCursorPos(_end)
      @editor.makePositionVisible(_beg)
      @editor.killSelection
      @editor.setSelection(_beg, _end-_beg)
      @editor.setFocus
    else
      @editor.killSelection
      @codecompletion.text = "<no result>"
     @editor.setFocus 
    end
  end
  
  def terminal
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    ini = IniReader.new(filename)
    ini.parse
    system = ini.get_system
    run, terminal, interpreter = ini.get_content(system)
    thr = Thread.new { %x(#{terminal}) }
    #%x(#{terminal})
  end
  
  def run
    save
    return if @editor.filename == "noname" || @editor.filename == ""
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    ini = IniReader.new(filename)
    ini.parse
    system = ini.get_system
    run, terminal, interpreter = ini.get_content(system)
    run.gsub!("{}", @editor.filename)
    
    file_extension = File.extname(@editor.filename)
    link = @editor.filename
    puts file_extension
    
    # html file ?
    if file_extension == ".html" || file_extension == ".htm"
      puts "yes"
      if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
        system "start #{link}"
      elsif RbConfig::CONFIG['host_os'] =~ /darwin/
        system "open #{link}"
      elsif RbConfig::CONFIG['host_os'] =~ /linux|bsd/
        system "xdg-open #{link}"
      end
    # run all non-html
    else
      thr = Thread.new { %x(#{run}) }
      #%x(#{run})
    end
  end
  
  def tab_contextmenu(sender, sel, event)
    unless event.moved?
      contextmenu = FXMenuPane.new(@tabbook) do |menu_pane|
        x = @tabbook.getCurrent
        cur_tab = @tab_list[x][0]
        text = cur_tab.text
        close = FXMenuCommand.new(menu_pane, "Close last tab: <#{text}>")

        close.connect(SEL_COMMAND) { close_tab }
        menu_pane.create
        menu_pane.popup(nil, event.root_x, event.root_y)
        app.runModalWhileShown(menu_pane)
      end
    end
  end
  
  def close_tab
    @tabbook.remove_last_tab
    @tab_list.pop
    new if @tab_list.size == 0
    editor = @tab_list[@tab_list.size-1][1]
    set_widgets(editor)
    @tabbook.setCurrent(@tab_list.size-1)
    @editor.setFocus
  end
 
  def get_autocomplete_list
    l = []
    text = @editor.text
    text = text.encode("UTF-8", invalid: :replace, replace: "")
    mod_text = text.tr("=", " ")
    mod_text = mod_text.tr(":.\"','`", " ")
    mod_text = mod_text.tr("(){}[]|*", " ")
    lines = mod_text.lines
    raw_list = []
    lines.each do |line|
      line = line.strip
      if line.start_with?('#')
        next
      elsif line.include?(" ")
        l = line.split(" ")
        l.each do |word|
          raw_list << word
        end
      else
        raw_list << line 
      end
    end
    #p raw_list
    words = []
    keywords = @editor.keywords
    operators = @editor.second_list
    raw_list.each do |word|
      word = word.chomp
      if keywords.include?(word)
        next
      elsif operators.include?(word)
        next
      elsif word.include?("/") || word.include?("\\n") || word.include?("\\t")
        next
      elsif word.start_with?("#")
        next
      elsif word.size <=2 || word.size >=16
        next
      else
        words << word
      end
    end
    words += keywords
    raw_set = Set.new(words)
    final_list = raw_set.to_a
    #p final_list.sort
    #puts final_list.size
    final_list.sort
  end
  
  def show_completion(word)
    @codecompletion.text = word
    if word == ""
      @codecompletion.text = "---"
      reset_completion
    end
    if word == nil
      @codecompletion.text = "---"
    end
  end
  
  def reset_completion
    @codecompletion.text = "---"
  end
 
  def load_icon(filename)
    begin
      filename = File.join(File.dirname(__FILE__), "icons", filename)
      icon = nil
      File.open(filename, "rb") { |f|
        icon = FXPNGIcon.new(getApp(), f.read)
      }
      icon
    rescue
      raise RuntimeError, "Couldn't load icon: #{filename}"
    end
  end
  
  def create
    super
    show(PLACEMENT_SCREEN)
  end
end


if __FILE__ == $0
  FXApp.new do |app|
    app.setForeColor('black')
    app.setBaseColor('#6E6E6E')
    RRR.new(app)
    app.create
    app.run
  end
end