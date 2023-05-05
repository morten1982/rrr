# rrr
RapidRubyRecorder => Ruby Codeeditor / Ruby IDE

![alt text](https://github.com/morten1982/rrr/blob/master/icons/rrr_run.png)

# Description
Codeeditor / light IDE made with ruby for ruby development :) 
using FXRuby GUI

# Features
- > Just using FXText Widget => no scintilla ! 
- > Autocomplete with backtab, indent, linenumbers, syntax highlighting
- > Sourcecode analyzing
- > Run ruby scripts in console or show html in your favorite browser 
- > Open terminal and irb separated
- > Preferences in text file (rrr.ini) 
- > Filebrowser included (delete, rename ... files and folders)

- > should be cross platform :) -> but was tested only on linux !

# Requirements
fxruby

# Install
RapidRubyRecorder is using FXRuby (-> FoxGUI)

- 1.) sudo apt-get install libfox-1.6-dev \
                           libxrandr-dev \
                           pkg-config \
      or \
      sudo pacman -S fox \
      sudo pacman -S libxrandr \
 
- 2.) 

      gem install fxruby

or

      bundle install (via Gemfile)
 
# Run
'ruby rrr.rb'

# License
MIT -> feel free to fork it => make it better if you want to do this :)

# to DO
-> improve the comments highlighting /syntax highlighting in general
-> improve backtab
-> visualize brace matching
