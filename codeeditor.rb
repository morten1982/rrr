#!/usr/bin/env ruby

require 'fox16'
require 'fox16/undolist'
require_relative './inireader.rb'

include Fox

class Codeeditor < FXText
  attr_accessor :filebrowser,
                :filename,
                :autocomplete_list,
                :current_word,
                :completion_list
  
  attr_reader   :font,
                :undolist,
                :font_size,
                :keywords,
                :second_list
  
  MAXUNDOSIZE, KEEPUNDOSIZE = 200000, 100000
  
  def initialize(parent, filename, tab, filebrowser, rrr, *opts)
    super(parent, *opts)
    @keywords = %w(BEGIN END __ENCODING__ __END__ __FILE__ __LINE__ \
                 alias and begin break case defined? ensure \
                 false for in module next nil not or redo rescue retry \
                 return self super then true undef unless until \
                 when require require_relative class def end yield if
                 elsif else do while)
    @first_list = %w(BEGIN END __ENCODING__ __END__ __FILE__ __LINE__ \
                 alias and begin break case defined? ensure \
                 false for in module next nil not or redo rescue retry \
                 return self super then true undef unless until \
                 when require require_relative puts gets)
    @second_list = ["+", "-", "*", "/", "=", "<", ">", "<<", "<=", ">=",
                    "&", "!=", "!", "+=", "-=", "*=", "/=",  "=>", "<=>",
                    ":", "|", "~", "::", "||", "&&", "~>", "~<", "$", "%",
                    "%w", "%x", "%r", "%i", "%q", "=~", "?" ".." "...",
                    "**","==", "===", "%=", "**=", "^", ">>", "?"]
    @third_list = %w(class def end yield if elsif else do while)
    @filename = filename
    @tab = tab
    @filebrowser = filebrowser
    @rrr = rrr
    @undolist = FXUndoList.new
    @font_size = 12
    @tabwidth = 2
    @autocomplete_list = []
    @completion_list = []
    @written_word = ""
    @clipboard = ""
    init_editor
  end
  
  def init_editor
    # init tabwidth and size
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    ini = IniReader.new(filename)
    ini.parse
    @font_size = ini.get_size.to_i
    @tabwidth = ini.get_tabwidth.to_i
    
    # prepare undolist
    @undolist.mark
    set_editor_style
    highlight_text
    
    # events
    self.connect(SEL_KEYRELEASE) do |sender, sel, event|
      line_start = self.lineStart(self.cursorPos)
      line_end = self.lineEnd(self.cursorPos)
      check_key_release(event)
      highlight_line(line_start, line_end)
      get_current_word
    end
    
    self.connect(SEL_KEYPRESS) do |sender, sel, event|
      check_key_press(event)
    end
    
    self.connect(SEL_FOCUSIN) { on_focus } 
    self.connect(SEL_CHANGED) { on_changed }
    
    self.connect(SEL_INSERTED) do |sender, sel, change|
      on_text_inserted(sender, sel, change)
    end
    self.connect(SEL_REPLACED) do |sender, sel, change|
      on_text_replaced(sender, sel, change)
    end
    self.connect(SEL_DELETED) do |sender, sel, change|
      on_text_deleted(sender, sel, change)
    end
    
    # context menu
    self.connect(SEL_RIGHTBUTTONPRESS) do |sender, sel, event|
      editor_contextmenu(sender, sel, event)
    end
    
    # set linenumbers
    self.setBarColumns(4)          # width for linenumbers
    self.setBarColor("#003300")    # color for linenumbers label
    self.setNumberColor("white")   # color for linenumbers numbers  
    self.setCursorColor("red")   
    self.setTabColumns(@tabwidth)  # whitespaces per tab
    
    # scrollbars
    hscroll = horizontalScrollBar
    vscroll = verticalScrollBar
    hscroll.setBackColor('#054C53')
    vscroll.setBackColor('#054C53')
    
  end
  
  def check_key_press(event)
    word = @rrr.codecompletion.text
    @written_word << event.text
    #p @written_word
    #puts "code: " + event.code.to_s
    #puts "state: " + event.state.to_s
    if event.code == KEY_Tab && word == ""
      reset_written_word
      @rrr.reset_completion
      false
    # input codecompletion ...
    elsif event.code == KEY_Tab && word != "---"
      pos = cursorPos
      line_start = self.lineStart(pos)
      line_end = self.lineEnd(pos)
      
      begin 
        text_line = self.extractText(line_start, line_end-line_start)
      rescue
        text_line = self.extractText(line_start, (line_end-line_start)-1)
      end
      text_length = text_line.length
      #@written_word = @written_word.chop
      @written_word.gsub!("\t", "")
      @written_word.gsub!(/[^[:word:]\s]/, '')
      puts "written_word: " + @written_word
      ##
      # is exactly one to change ?
      ##
      count = text_line.scan(/(?=#{@written_word})/).count
      p count
      if count == 1
        new_line = text_line.gsub(@written_word, word)
        self.removeText(line_start, text_length)
        self.insertText(line_start, new_line)
    
        highlight_line(line_start, line_end)
        @rrr.reset_completion
        reset_written_word
      else
        reset_written_word
        @rrr.reset_completion
      end
    elsif event.code == KEY_BackSpace
      puts event.state
      # look for whitespaces and make backtab...
      pos = cursorPos
      line_start = lineStart(pos)
      line_end = lineEnd(pos)
      l = line_end-line_start
      text = extractText(line_start, l)
      text = text.encode("UTF-8", invalid: :replace, replace: "")
      if pos-2 >= 2
        cursor_left2_string = extractText(pos-2, 2)
      else
        cursor_left2_string = nil
      end
      whitespaces = text.size - text.lstrip.size
      # 2 => tabsize
      if whitespaces.even? && whitespaces >= 2
        if cursor_left2_string == "  "
          self.removeText(pos-2, 2)
        else
          false
        end
      else
        false
      end
    elsif (event.code == 228) || (event.code == 246) || (event.code == 252)
      return
    elsif event.state == 17 && ((event.code == 214) || (event.code == 196) || (event.code == 220))
      # shift key + umlaut
      return
    elsif event.state == 144 && ((event.code == 178) || (event.code == 179))
      # alt gr + 2 || 3
      return
    elsif event.state == 17 && event.code == 167
      # shift + 3
      return
    elsif (event.code == 223) || (event.code == 176)
      return
    # -> Control Key is pressed & key_c
    #elsif event.state == 20 && event.code == 99 
    #  context_copy
    # -> Control Key is pressed & key_x      
    #elsif event.state == 20 && event.code == 120
    #  context_cut
    # -> Control Key is pressed & key_v
    #elsif event.state == 20 && event.code == 118
    #  context_paste
    else
      @rrr.reset_completion
      # propagate event
      false
    end
  end
  
  def check_key_release(event)
    keycode = event.code
    #p keycode
    if keycode == KEY_Return
      @completion_list = []
      @autocomplete_list = @rrr.get_autocomplete_list
      #puts "->"
      #p @autocomplete_list
      #puts "<-"
      line_start = self.lineStart(self.cursorPos)
      line_start_prev = self.prevLine(self.cursorPos)
      line_end_prev = self.lineEnd(line_start)
      l_prev = line_end_prev-line_start_prev
      text_prev = self.extractText(line_start_prev, l_prev)
      unhighlight_line(line_start_prev, line_end_prev, text_prev)
      highlight_line(line_start_prev, line_end_prev)
      
      @rrr.reset_completion
      reset_written_word
      @rrr.codeview.init_tree
      
      making_end(text_prev.chop!)
      
    elsif (keycode == KEY_space || keycode == KEY_Up || keycode == KEY_Down ||
                      keycode == KEY_Left || keycode == KEY_Right)
      @rrr.reset_completion
      reset_written_word
      @rrr.codeview.init_tree
    elsif keycode == KEY_BackSpace
      # when delete -> update codeview
      @rrr.codeview.init_tree
      @rrr.reset_completion
      reset_written_word
    elsif keycode == KEY_Control_R || keycode == KEY_Control_L 
      highlight_text
    #                (                )                .                :
    elsif keycode == 40 || keycode == 41 || keycode == 46 || keycode == 58
      reset_written_word
    else
      line_start = self.lineStart(self.cursorPos)
      line_end = self.lineEnd(self.cursorPos)
      l = line_end-line_start
      text_cur = self.extractText(line_start, l)
      unhighlight_line(line_start, line_end, text_cur)
      highlight_line(line_start, line_end)
    end
    
    # Event for enter and deleting chars
    if FXText::ID_PASTE_SEL || FXText::ID_CUT_SEL
      pos = cursorPos
      line_start = lineStart(pos)
      line_end = lineEnd(pos)
      highlight_line(line_start, line_end)
      @rrr.reset_completion
      return
    end
  end
  
  def making_end(text)
    words = text.split 
    signal = %w(while for do until class def if begin unless case)
    words.each do |word|
      if signal.include? word
        whitespaces = text.size - text.lstrip.size
        pos = self.cursorPos
        
        start_next_line = self.nextLine(pos)
        end_next_line = self.lineEnd(start_next_line)
        l = end_next_line - start_next_line
        check_text = self.extractText(start_next_line, l) 
        w_check_text = check_text.size - check_text.lstrip.size
        return if check_text.include?("end") && w_check_text == whitespaces
    
        self.insertText(pos, "\n")
        to_insert = " " * whitespaces + "end\n"
        self.insertText(start_next_line, to_insert)
        
        line_start = lineStart(start_next_line)
        line_end = lineEnd(start_next_line)
        highlight_line(line_start, line_end)
        
        self.setCursorPos(pos)
      end
    end
  end
  
  def reset_written_word
    @written_word = ""
  end
  
  def set_editor_style
    self.font = FXFont.new(app, "Mono", @font_size)
    @font = self.font
    self.setBackColor('#0b0b0b')
    self.setTextColor('white')
    
    self.styled = true
    keyword_style = FXHiliteStyle.from_text(self)
    keyword_style.normalForeColor = "cyan"
    operator_style = FXHiliteStyle.from_text(self)
    operator_style.normalForeColor = "red"
    oop_style = FXHiliteStyle.from_text(self)
    oop_style.normalForeColor = "darkgreen"
    instances_style = FXHiliteStyle.from_text(self)
    instances_style.normalForeColor = "orange"
    comments_style = FXHiliteStyle.from_text(self)
    comments_style.normalForeColor = "#999966"
    self.hiliteStyles = [keyword_style, operator_style, oop_style, \
                            instances_style, comments_style]
  end
  

  
  def prepare_colorize(word, line_start, line_end)
    if word.start_with?("@") 
      colorize(word, line_start, nil, 4)
    else
      colorize(word, line_start, @first_list, 1)
      colorize(word, line_start, @second_list, 2)
      colorize(word, line_start, @third_list, 3)
    end
    
    line_start += word.length
  end
  
  def colorize(word, pos, list=nil, scheme)
    if list != nil
      list.each do |keyword|
        if word == keyword
          first, last = self.findText(word, :start => pos)
          pos = first[0].to_i
          current_word_start_pos = self.wordStart(pos)
          if current_word_start_pos == pos
            self.changeStyle(first[0], last[0]-first[0], scheme)
          end
        end
      end
    else
      first, last = self.findText(word, :start => pos)
      pos = first[0].to_i
      current_word_start_pos = self.wordStart(pos)
      if current_word_start_pos == pos
        self.changeStyle(first[0], last[0]-first[0], scheme)
      end
    end
  end

  def highlight_text
    # color all text (e.g when loading file)
    pos = 0
    text_lines = self.text.lines
    text_lines.each do |line|
      l = line.length
      begin
        line = line.tr("//^(){}[]|.,", " ")
      rescue
        return
      end
      start_pos = pos
      end_pos = pos+l
      highlight_line(start_pos, end_pos)
      check_comments(start_pos, end_pos)
      pos += l
    end
  end
  
  def highlight_line(line_start, line_end)
    l = line_end-line_start
    text = self.extractText(line_start, l)
    begin
      t = text.tr("//^(){}[]|.,", " ")
    rescue
      #puts text
      return
    end
    words = t.split
    words.each do |word|
      if word.include?("#") 
        check_comments(line_start, line_end) 
      else
        prepare_colorize(word, line_start, line_end)
      end
    end

  end

  def unhighlight_line(line_start, line_end, text)
    pos = self.cursorPos
    l = text.length
    self.removeText(line_start, l)
    self.insertText(line_start, text)
    self.setCursorPos(pos)
  end
  
  def check_comments(line_start, line_end)
    x = self.lineEnd(line_start)
    # important line if user writes at end of document !
    if x == self.cursorPos then return end 
    
    text = self.extractText(line_start, line_end-line_start)
    comment_pos = text.index("#")
    
    line_start_pos = self.lineStart(line_start)
    
    if comment_pos
      pos = line_start_pos+comment_pos
      next_character = self.extractText(pos+1, 1)
      #puts "-> " + next_character
      if next_character != "{" && next_character 
        #puts "yes"
        colorize_comments(pos) 
      end
    end
  end
  
  def colorize_comments(start_pos)
    #puts start_pos
    line_start = self.lineStart(start_pos)
    line_end = self.lineEnd(start_pos)
    begin
      text = self.extractText(line_start, line_end-line_start)
      pos = text.index('#')
      if pos && (line_end != self.cursorPos)
        self.changeStyle(start_pos, line_end-start_pos, 5)
      end
      #colorize_comments(pos)
    rescue
      return
    end
  end
  
  def load_file(filename)
    begin
      data = ''
      f = File.open(filename, "r") 
      f.each_line do |line|
        data += line
      end
      f.close
    rescue => e
      message = FXMessageBox.error(@rrr, MBOX_OK, "Error", e.message)
      return
    end
    
    @undolist.clear
    @undolist.mark
    data = data.encode("UTF-8", invalid: :replace, replace: "")
    return data
  end
  
  def save_file(filename)
    begin
      data = self.text
      f = File.open(filename, "w")
      data.each_line do |line|
        f.write(line)
      end
      f.close
    rescue => e
      message = FXMessageBox.error(@rrr, MBOX_OK, "Error", e.message)
      return
    end
    
    @rrr.setTitle(@filename)
    @undolist.clear
    @undolist.mark
  end
  
  def get_name_of_file
    if filename.include?("/")
      file = filename.split("/")[-1]
    else
      file = "noname"
    end
  end
  
  def set_tab_text
    text = @tab.getText
    return if text.end_with?("*") 
    tab_text = get_name_of_file
    @tab.setText(tab_text)
  end
  
  def change_tab_text(text)
    @tab.setText(text)
  end
  
  def on_changed
    name = @tab.text
    return if name.end_with?("*") || name == "noname"
    name += "*"
    @tab.setText(name)
    @rrr.setTitle(@filename)
  end
  
  def get_current_word
    #  --> <-- #
    return if @written_word.size < 3
    word_start = self.wordStart(cursorPos-1)
    cursor_pos = self.cursorPos
    word = self.extractText(word_start, cursor_pos-word_start)
    @completion_list = []
    if word.size >= 3
      @autocomplete_list.include?(word)
        @autocomplete_list.each do |item|
          if item.start_with?(word)
            @completion_list << item
          end
        end  
        index = @autocomplete_list.find_index(word)
        #p index
        @rrr.show_completion(@completion_list[0]) 
        if index
          #@rrr.show_completion(@autocomplete_list[index])
          @rrr.reset_completion
          @rrr.codecompletion.text = "---"
        end
    end
  end
  
  def on_focus
    path = File.dirname(filename)
    @filebrowser.change_dir(path)
  end
  
  def clear
    self.text = ""
  end
  
  def comment_line(line_start, line_end)
    puts "here"
    if line_end == self.cursorPos then return end 
    words = extractText(line_start, line_end)
    puts words
  end
  
  def on_text_inserted(sender, sel, change)
    @undolist.add(FXTextInsert.new(self, change.pos))
    @undolist.trimSize(KEEPUNDOSIZE) if (@undolist.undoSize() > MAXUNDOSIZE)
    return 1
  end
  
  def on_text_deleted(sender, sel, change)
    @undolist.add(FXTextDelete.new(self, change))
    @undolist.trimSize(KEEPUNDOSIZE) if (@undolist.undoSize() > MAXUNDOSIZE)
    return 1
  end

  # Text replaced
  def on_text_replaced(sender, sel, change)
    @undolist.add(FXTextReplace.new(self, change))
    @undolist.trimSize(KEEPUNDOSIZE) if (@undolist.undoSize() > MAXUNDOSIZE)
    return 1
  end
  
  def undo
    if @undolist.canUndo?
      @undolist.undo
      self.setFocus
    else
      self.setFocus
      return
    end
  end
  
  def redo
    if @undolist.canRedo?
      @undolist.redo
      self.setFocus
    else
      self.setFocus
      return
    end
  end
  
  def zoomIn
    @font_size += 1
    font = FXFont.new(getApp(), "Mono", @font_size)
    font.create
    self.font = font
    self.update
    return
  end
  
  def zoomOut
    @font_size -= 1 
    font = FXFont.new(getApp(), "Mono", @font_size)
    font.create
    self.font = font
    self.update
    return
  end
  
  def editor_contextmenu(sender, sel, event)
    unless event.moved?
      contextmenu = FXMenuPane.new(self) do |menu_pane|
        FXMenuCommand.new(menu_pane, "Undo", nil, @undolist, FXUndoList::ID_UNDO)
        FXMenuCommand.new(menu_pane, "Redo", nil, @undolist, FXUndoList::ID_REDO)
        FXMenuSeparator.new(menu_pane)
        FXMenuCommand.new(menu_pane, "Cut", nil, self, FXText::ID_CUT_SEL)
        FXMenuCommand.new(menu_pane, "Copy", nil, self, FXText::ID_COPY_SEL)
        FXMenuCommand.new(menu_pane, "Paste", nil, self, FXText::ID_PASTE_SEL)
        FXMenuSeparator.new(menu_pane)
        select_all_context = FXMenuCommand.new(menu_pane, "Select All")
        select_all_context.connect(SEL_COMMAND) { context_select_all }
        highlight_all_context = FXMenuCommand.new(menu_pane, "Highlight All")
        highlight_all_context.connect(SEL_COMMAND) { highlight_text }
        FXMenuSeparator.new(menu_pane)
        terminal_context = FXMenuCommand.new(menu_pane, "Open Terminal")
        terminal_context.connect(SEL_COMMAND) { @rrr.terminal }
        menu_pane.create
        menu_pane.popup(nil, event.root_x, event.root_y)
        
        app.runModalWhileShown(menu_pane)
      end
    end
  end
  
  
  def context_select_all
    _start = 0
    _end = 0
    text_lines = self.text.lines
    text_lines.each do |line|
      l = line.length
      _end += l
    end
    self.setSelection(_start, _end)
  end
  
end

