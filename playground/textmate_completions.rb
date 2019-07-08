#!/usr/bin/env ruby


require 'rubygems'
require_gem 'contextsetup'
# or
# require 'tex/context/contextsetup'

# src=File.read("../test/testsetup-en.xml")
src=File.read(`kpsewhich cont-en.xml`.chomp)

class Plist
  def Plist.output(what)
    unless Hash===what
      raise ArgumentError,"root must be a Hash object"
    end
    tmp='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
'
    tmp << what.to_plist(1) << "</plist>\n"
    tmp
  end
end
class String
  def to_plist(level=0)
    "  "*level + "<string>#{self.to_s}</string>\n"
  end
end
class Array
  def to_plist(level=0)
    tmp="  "*level + "<array>\n"
    self.each do |elt|
      tmp << elt.to_plist(level + 1)
    end
    tmp << "  "*level + "</array>\n"
    tmp
  end
end
class Hash
  def to_plist(level=0)
    tmp="<dict>\n"
    self.each do |key, value|
      tmp << "  "*(level + 1) + "<key>#{key}</key>\n"
      tmp << value.to_plist(level + 1)
    end
    tmp << "</dict>\n"
    tmp
  end
end
class TrueClass
  def to_plist(level=0)
    "<true />"
  end
end
class Integer
  def to_plist(level=0)
    "<integer>#{self}</integer>"
  end
end
class FalseClass
  def to_plist(level=0)
    "<false />"
  end
end



root=REXML::Document.new(src).root

en=ConTeXtSetup::Interface.parse_xml(root)

# we are only interested in those commands, that actually exist
interesting_commands = en.commands.collect do |cmd,variants|
  variants.reject do |var|
    if var.has_variable?
      puts "rejecting #{var.cmd_name}"
    else
      puts "including #{var.cmd_name}"
    end
    var.has_variable?
  end
end.flatten.sort_by { |cmd| cmd.cmd_name(false) }


completions = interesting_commands.collect do |cmd|
  cmd.cmd_name(false)
end

root= { "name"  => "completions",
  :scope => "text.tex.context",
  :settings => { :completions => completions },
  :uuid => `uuidgen`.chomp 
}

File.open("completions.plist", "w") do |file|
  file << Plist.output(root)
end
