require 'fox16'
require_relative './codeparser.rb'

include Fox

class Codeview < FXTreeList
  
  attr_reader   :both,
                :classes,
                :functions
              
  attr_accessor :editor
  
  def initialize(parent, editor, *opts)
    super(parent, *opts)

    @editor = editor
    @both = {}
    @classes = {}
    @functions = {}
    
    self.setTextColor('white')
    self.setBackColor('#0b0b0b')
    self.setLineColor('white')
    self.setSelBackColor('#013ADF')
    self.setSelTextColor('#FFFF00')
    self.setListStyle(2)
    self.repaint()


    # scrollbars
    hscroll = horizontalScrollBar
    vscroll = verticalScrollBar
    hscroll.setBackColor('#054C53')
    vscroll.setBackColor('#054C53')
    
    self.connect(SEL_SELECTED) do |sender, sel, item|
      @selected_item = []
      @selected_item << item
    end
    
    self.connect(SEL_DOUBLECLICKED) do |sender, sel, current|
      item = @selected_item[0] if @selected_item
      line = item.data
      @editor.setCursorRow(line)
      pos = @editor.getCursorPos
      line_end = @editor.lineEnd(pos)
      @editor.setCursorPos(line_end)
      @editor.makePositionVisible(pos)
      pos_start = @editor.lineStart(pos)
      @editor.killSelection
      @editor.setSelection(pos_start, line_end-pos_start)
      @editor.setFocus
      end
    
    #init_tree
  end

  def delete_tree
    self.clearItems
  end  

  def init_code
    text = @editor.text
    code = Codeparser.new(text)
    code.parse_text
    @both = code.both
    @classes = code.classes
    @functions = code.functions
  end
 
  def init_tree
    delete_tree
    init_code
    @both.each do |key, value|
      if value.start_with?("class")
        item = self.appendItem(nil, value)
        key -= 1
        item.data = key
      else
        item = self.appendItem(nil, value)
        key -= 1
        item.data = key
      end  
    end
  end
  
end
