require 'fox16'
require_relative './codeeditor.rb'

include Fox

##
# PicButton
##
class PicButton < FXButton
  
  def initialize(parent, *opts)
    super
    setup_button
  end
  
  def setup_button
    setBackColor('#0b0b0b')
    setTextColor('white')
    setHiliteColor('darkred')
    setShadowColor('darkred')
    setBorderColor('darkred')
    setBaseColor('darkred')
  end
end

##
# NoteBook
##
class NoteBook < FXTabBook
  attr_accessor :rrr
  
  def initalize(parent, rrr, *opts)
    super(parent, *opts)
    @rrr = rrr
    #self.connect(SEL_COMMAND) { on_change_tab }
    setup_item
  end
  
  def setup_item
    setBackColor('#0b0b0b')
    setTextColor('white')
  end
  
  def remove_last_tab
    numTabs = self.numChildren/2
    doomedTab = numTabs - 1
    self.removeChild(self.childAtIndex(2*doomedTab+1))
    self.removeChild(self.childAtIndex(2*doomedTab))
  end
end

##
# TabItem
##
class TabItem < FXTabItem

  def initialize(parent, *opts)
    super
    setup_item
  end
  
  def setup_item
    setBackColor('#003300')
    setTextColor('white')
    setHiliteColor('darkgreen')
    setBorderColor('darkgreen')
    setShadowColor('darkgreen')
  end
end
