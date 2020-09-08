require 'fox16'
require_relative './inireader.rb'

include Fox

class SettingsDialog < FXDialogBox
  
  def initialize(parent)
    super(parent, "Settings", DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE)
    add_terminating_buttons
    add_tabbook
  end

  def add_terminating_buttons
    buttons = FXHorizontalFrame.new(self,
      :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM|PACK_UNIFORM_WIDTH)
    okButton = FXButton.new(buttons, "OK",
      :target => self,
      :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
    okButton.connect(SEL_COMMAND) { save_status }
  end
  
  def add_tabbook
    tabbook = FXTabBook.new(self, :opts => LAYOUT_FILL)
    commands_tab = FXTabItem.new(tabbook, " Commands ")
    @commands_page = FXVerticalFrame.new(tabbook, :opts => FRAME_RAISED|LAYOUT_FILL)
    editor_tab = FXTabItem.new(tabbook, " Editor ")
    @editor_page = FXVerticalFrame.new(tabbook, :opts => FRAME_RAISED|LAYOUT_FILL)
    
    construct_commands_page(@commands_page)
    construct_editor_page(@editor_page)
  end
  
  def construct_commands_page(page)
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    ini = IniReader.new(filename)
    ini.parse
    system = ini.get_system
    content = ini.get_content(system)
    run, terminal, interpreter = content

    form = FXMatrix.new(page, 2, :opts =>MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
    FXLabel.new(form, "Run Command ({} = Filename): ")
    @run_field = FXTextField.new(form, 40,
      :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @run_field.setText(run)

    FXLabel.new(form, "Terminal Command: ")
    @terminal_field = FXTextField.new(form, 40,
      :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @terminal_field.setText(terminal)

    FXLabel.new(form, "Interpreter Command: ")
    @interpreter_field = FXTextField.new(form, 40,
      :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @interpreter_field.setText(interpreter)
    @system_label = FXLabel.new(form, "System: " + system)
    
    buttonframe = FXHorizontalFrame.new(form,
      :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM|PACK_UNIFORM_WIDTH)
    
    mate = FXButton.new(buttonframe, "Mate")
    mate.connect(SEL_COMMAND) { set_new_system("mate") }
    gnome = FXButton.new(buttonframe, "Gnome")
    gnome.connect(SEL_COMMAND) { set_new_system("gnome") }
    kde = FXButton.new(buttonframe, "KDE")
    kde.connect(SEL_COMMAND) { set_new_system("kde") }
    xterm = FXButton.new(buttonframe, "XTerm")
    xterm.connect(SEL_COMMAND) { set_new_system("xterm") }
    win = FXButton.new(buttonframe, "Windows")
    win.connect(SEL_COMMAND) { set_new_system("windows") }
    mac = FXButton.new(buttonframe, "Mac")
    mac.connect(SEL_COMMAND) { set_new_system("mac") }
  end
  
  def construct_editor_page(page)
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    ini = IniReader.new(filename)
    ini.parse
    tabwidth = ini.get_tabwidth
    font = ini.get_font
    size = ini.get_size
    
    form = FXMatrix.new(page, 2, :opts =>MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
    FXLabel.new(form, "Tab Width (in whitespaces): ")
    @tabwidth_list = FXListBox.new(form,
      :opts => LISTBOX_NORMAL|FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)
    @tabwidth_list.appendItem("2")
    @tabwidth_list.appendItem("4")
    @tabwidth_list.appendItem("8")
    x = tabwidth.to_i
    if x == 4
      @tabwidth_list.setCurrentItem(1)
    elsif x == 8
      @tabwidth_list.setCurrentItem(2)
    else
      @tabwidth_list.setCurrentItem(0)
    end
    FXLabel.new(form, "Font Size (6 <= x <= 64): ")
    @size_field = FXTextField.new(form, 40,
      :opts => TEXTFIELD_INTEGER|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
    @size_field.setText(size)
    FXLabel.new(form, "\nChanges in this area will appear on restart or new editor tab")
  end

  def set_new_system(system)
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    ini = IniReader.new(filename)
    ini.set_system(system)
    ini = IniReader.new(filename)
    ini.parse
    system = ini.get_system
    content = ini.get_content(system)
    run, terminal, interpreter = content
    @run_field.setText(run)
    @terminal_field.setText(terminal)
    @interpreter_field.setText(interpreter)
    @system_label.setText("System: " + system)
  end
  
  def save_status
    dir = File.dirname(__FILE__) + "/"
    filename = dir + "rrr.ini"
    ini = IniReader.new(filename)
    ini.parse
    system = ini.get_system
    run = @run_field.text
    terminal = @terminal_field.text
    interpreter = @interpreter_field.text
    x = @tabwidth_list.getCurrentItem
    tabwidth = "2" if x == 0
    tabwidth = "4" if x == 1
    tabwidth = "8" if x == 2
    size = @size_field.text
    ini.set_ini_file(system, run, terminal, interpreter, tabwidth, size)
    getApp().stopModal(self, 1)
    hide
  end
end