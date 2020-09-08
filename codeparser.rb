class Codeparser
  attr_reader :classes,
              :functions,
              :both
  
  def initialize(text)
    @text = text
    @classes = {}
    @functions = {}
    @both = {}
  end
  
  def parse_text
    linenumber = 0
    @text.each_line do |line|
      linenumber += 1
      line = line.encode("UTF-8", invalid: :replace, replace: "")
      if line.strip.start_with?('class')
        #puts " #{linenumber}  #{line}"
        @classes[linenumber] = line.strip
        @both[linenumber] = line.strip
      elsif line.strip.start_with?('def')
        #puts " #{linenumber}  #{line}"
        @functions[linenumber] = " -> " + line.strip
        @both[linenumber] = " -> " + line.strip
      end
    end
  end
  
end