require 'fox16'
require_relative 'files.rb'
require 'fileutils'

include Fox

class Filebrowser < FXTreeList
  
  attr_accessor :fof,
                :editor,
                :rrr
  
  def initialize(parent, *opts)
    super

    self.setTextColor('white')
    self.setBackColor('#0b0b0b')
    self.setLineColor('white')
    self.setSelBackColor('#013ADF')
    self.setSelTextColor('#FFFF00')
    self.setListStyle(2)
    self.repaint()
    @editor = nil
    @rrr = nil
    @selected_item = []
    @selected_path = ""

    # scrollbars
    hscroll = horizontalScrollBar
    vscroll = verticalScrollBar
    hscroll.setBackColor('#054C53')
    vscroll.setBackColor('#054C53')

    self.connect(SEL_SELECTED) do |sender, sel, item|
      @selected_item = []
      @selected_item << item
    end
    
    self.connect(SEL_RIGHTBUTTONPRESS) do |sender, sel, event|
      if @selected_item != []
        x = event.click_x
        y = event.click_y
        p x
        p y
        item = self.getItemAt(x, y)
        if item == @selected_item[0]
          filebrowser_contextmenu(sender, sel, event)
        end
      end
    end    
    
    self.connect(SEL_DOUBLECLICKED) do |sender, sel, current|
      item = @selected_item[0].to_s if @selected_item
      if item.include? "["
        change_directory_inside(item)
      else
        open_file(item)
        @editor.setCursorPos(0)
        @editor.setFocus
      end
    end
    
    init_tree
  end
  
  def init_tree
    delete_tree
    @fof = FilesAndFolders.new
    all = @fof.return_all
    files = @fof.return_files
    folders = @fof.return_folders

    folders.each do |item|
      self.appendItem(nil, item)
    end
    
    files.each do |item|
      self.appendItem(nil, item)
    end
    
    if @rrr != nil
      filename = @editor.filename if @editor
      if filename
        @rrr.setTitle(filename)
      else
        @rrr.setTitle(@fof.cwd)
      end
    end
  end
  
  def delete_tree
    self.clearItems
  end
  
  def open_file(item)
    if @editor.text != ""
      message = FXMessageBox.question(@rrr, 
                                      MBOX_YES_NO,
                                      "Open File ?", 
                                      "Open file in current editor window?")
      if message == MBOX_CLICKED_NO
        return
      end
    end
    filename = @fof.cwd + item
    begin
      text = @editor.load_file(filename)
      @editor.filename = filename
      @editor.clear
      @editor.appendText(text)
      @editor.highlight_text
      file = @editor.get_name_of_file
      @editor.change_tab_text(file)
      #@rrr.codeview.editor = @editor
      @editor.completion_list = []
      @editor.autocomplete_list = @rrr.get_autocomplete_list
      @rrr.codeview.init_tree
      set_title
    rescue => e
      p e
      message = FXMessageBox.error(@rrr, MBOX_OK, "Error", e.message)
      reset_editor(@editor)
      return
    end
  end
  
  def set_title
    if @editor.filename != "noname"
      @rrr.setTitle(@editor.filename)
    end
  end
  
  def change_directory_inside(item)
    item = item.delete("[]")
    #p "change directory " + item
    if item == ".."
      Dir.chdir("..")
    else
      begin
        Dir.chdir(@fof.cwd + item)
      rescue => e
        message = FXMessageBox.error(@rrr, MBOX_OK, "Error", e.message)
        return
      end
    end
    init_tree
  end
  
  def change_dir(dir)
    Dir.chdir(dir)
    init_tree
  end
  
  def reset_editor(editor)
    editor.filename = "noname"
    editor.text = ""
    @rrr.set_widgets(editor)
    @rrr.change_directory(editor)
    @editor = editor
  end
  
  def filebrowser_contextmenu(sender, sel, event)
    unless event.moved?
      contextmenu = FXMenuPane.new(self) do |menu_pane|
        info_context = FXMenuCommand.new(menu_pane, "Info")
        info_context.connect(SEL_COMMAND) { context_info }
        FXMenuSeparator.new(menu_pane)
        create_folder_context = FXMenuCommand.new(menu_pane, "Create New Folder")
        create_folder_context.connect(SEL_COMMAND) { context_create_folder }
        FXMenuSeparator.new(menu_pane)
        copy_context = FXMenuCommand.new(menu_pane, "Copy Item")
        copy_context.connect(SEL_COMMAND) { context_copy }
        paste_context = FXMenuCommand.new(menu_pane, "Paste Item")
        paste_context.connect(SEL_COMMAND) { context_paste }
        rename_context = FXMenuCommand.new(menu_pane, "Rename Item")
        rename_context.connect(SEL_COMMAND) { context_rename }
        FXMenuSeparator.new(menu_pane)
        delete_context = FXMenuCommand.new(menu_pane, "Delete Item")
        delete_context.connect(SEL_COMMAND) { context_delete }
        FXMenuSeparator.new(menu_pane)
        refresh_context = FXMenuCommand.new(menu_pane, "Refresh Tree")
        refresh_context.connect(SEL_COMMAND) { init_tree }
        terminal_context = FXMenuCommand.new(menu_pane, "Open Terminal")
        terminal_context.connect(SEL_COMMAND) { @rrr.terminal }
        menu_pane.create
        menu_pane.popup(nil, event.root_x, event.root_y)
        
        app.runModalWhileShown(menu_pane)
      end
    end
  end
  
  def context_info
    puts "Info..."
    item = @selected_item[0]
    text = item.text
    text = text.gsub("[", "").gsub("]", "")
    
    # read / write / exec / size / owner / created
    l = []
    l << File.file?(text)
    l << File.readable?(text)
    l << File.writable?(text)
    l << File.executable?(text)
    l << File.size(text)
    
    info = "Name: " + text + "\n\n"
    if l[0].to_s == "true"
      info += "Type: File\n"
    else
      info += "Type: Directory\n"
    end
    info += "\nreadable: " + l[1].to_s + "\n"
    info += "writable: " + l[2].to_s + "\n"
    info += "executable: " + l[3].to_s + "\n"
    info += "\nSize: " + l[4].to_s + " bytes \n"

    FXMessageBox.information(self, MBOX_OK, "Info", info)

  end

  def context_create_folder
    dialog = FXInputDialog.new(self, "Create Directory", "Enter name:")
    if dialog.execute != 0
      dirname = dialog.text
      begin
        Dir.mkdir(dirname)
      rescue => e
        FXMessageBox.error(self, MBOX_OK, "Error", e.message)
      end
      init_tree
      @rrr.setTitle("<Folder created>")
    end
  end
  
  def context_copy
    text = @selected_item[0].text
    path =  Dir.pwd + "/"
    # folder
    if text.start_with?("[")
      pathname = text.gsub("[", "").gsub("]", "")
      if pathname == ".."
        fullpath = path
      else
        fullpath = path + pathname + "/"
      end
    # file
    else
      fullpath = path + text
    end
    
    @selected_path = fullpath
    @rrr.setTitle("< " + fullpath + " > selected")

  end
  
  def context_paste
    return if @selected_path == ""
    # file
    if File.file?(@selected_path)
      source = @selected_path
      destination = Dir.pwd + "/"
      begin
        FileUtils.cp(source, destination)
      rescue => e
        FXMessageBox.error(self, MBOX_OK, "Error", e.message)
      end
    # folder
    else
      source = @selected_path
      destination = Dir.pwd + "/"
      begin
        FileUtils.cp_r(source, destination)
      rescue => e
        FXMessageBox.error(self, MBOX_OK, "Error", e.message)
      end
    end
    init_tree
    @selected_path = ""
    @rrr.setTitle("<Done>")
  end
  
  def context_rename
    text = @selected_item[0].text
    path =  Dir.pwd + "/"
    # folder
    if text.start_with?("[")
      pathname = text.gsub("[", "").gsub("]", "")
      return if pathname == ".."
      fullpath = path + pathname

      dialog = FXInputDialog.new(self, "Rename Directory: " + pathname, "Enter name:")
      if dialog.execute != 0
        new_name = dialog.text
        newpath = path + new_name
        begin
          FileUtils.mv fullpath, newpath
        rescue => e
          FXMessageBox.error(self, MBOX_OK, "Error", e.message)
        end
      init_tree
      @rrr.setTitle("<Done>")
      end
      
    # file
    else 
      fullpath = path + text
      
      dialog = FXInputDialog.new(self, "Rename Filename: " + text, "Enter name:")
      if dialog.execute != 0
        new_name = dialog.text
        newpath = path + new_name
        begin
          FileUtils.mv fullpath, newpath
        rescue => e
          FXMessageBox.error(self, MBOX_OK, "Error", e.message)
        end
      init_tree
      @rrr.setTitle("<Done>")
      end
    end
  end
  
  def context_delete
    text = @selected_item[0].text
    path =  Dir.pwd + "/"
    # folder
    if text.start_with?("[")
      pathname = text.gsub("[", "").gsub("]", "")
      return if pathname == ".."
      fullpath = path + pathname
    # file
    else
      fullpath = path + text
    end
    dialog = FXMessageBox.question(self, MBOX_YES_NO, "Delete" , 
                               "Delete < " + fullpath + " >")
    if dialog == MBOX_CLICKED_YES
      # file 
      if File.file? fullpath
        begin
          File.delete(fullpath)
        rescue => e
          FXMessageBox.error(self, MBOX_OK, "Error", e.message)
        end
      # folder
      else
        begin
          FileUtils.remove_dir(fullpath)
        rescue => e
          FXMessageBox.error(self, MBOX_OK, "Error", e.message)
        end
      end
    end
    init_tree
    @rrr.setTitle("<Done>")
  end
end
    