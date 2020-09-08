class FilesAndFolders
  attr_accessor :cwd
  
  def initialize(dir=nil)
    if dir
      if dir.end_with? "/"
        @cwd = dir 
      else
        @cwd = dir + "/"
      end
    else
      @cwd = Dir.pwd + "/"
    end
    
    Dir.chdir(@cwd)
    
    @all = []
    @files = []
    @dirs = []
    
    get_all
  end
  
  def get_all
    @all = Dir.entries(@cwd)
    if @all.include? "."
      @all.delete(".") 
    end 
    @all.each do |item|
      if File.file?(item)
        @files << item
      else
        @dirs << "[" + item + "]"
      end
    end
    
    @files = @files.sort()
    
    @dirs = @dirs.sort()
    if @dirs.include? "[.]" 
      @dirs.delete("[.]")
    end
  end
  
  def return_all
    @all.sort
  end
  
  def return_files
    @files.sort
  end
  
  def return_folders
    @dirs.sort
  end
    
end


if __FILE__ == $0
  faf = FilesAndFolders.new
  faf2 = FilesAndFolders.new("/home/morten/Dokumente/quake3")

  puts "\n\n\t" + faf2.cwd
  puts
  puts faf2.return_all
  puts faf2.return_folders
end
