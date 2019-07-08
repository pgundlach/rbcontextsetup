#!/usr/bin/env ruby
#
#  Created by Patrick Gundlach on 2006-08-28.
#  Copyright (c) 2006. All rights reserved.

require 'rubygems'
# gem 'contextsetup'
$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require "tex/context/contextsetup"

src=File.read("../test/testsetup-en.xml")
src=File.read(`kpsewhich cont-en.xml`.chomp)


require 'cgi'
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
    "  "*level + "<string>#{CGI.escapeHTML(self.to_s)}</string>\n"
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

dir="/Users/pg/Library/Application Support/TextMate/Bundles/ConTeXt.tmbundle/Snippets"

interesting_commands.each do |cmd| 
  string=cmd.to_tm_snippet
  root={
    :content => string,
    :name => cmd.cmd_name(true),
    :scope => "text.tex.context",
    :tabTrigger => cmd.cmd_name(true),
    :uuid => `uuidgen`.chomp
  }
  filename = File.join(dir,cmd.cmd_name(true) + ".tmSnippet")
  puts filename
#  puts Plist.output(root)
  File.open(filename,"w") do |file|
    file << Plist.output(root)
  end
end