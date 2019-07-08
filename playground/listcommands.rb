#!/usr/bin/env ruby


# require 'rubygems'
require  '../lib/tex/context/contextsetup'
# require "rexml/document"

src=File.read("../test/testsetup-en.xml")
# src=File.read(`kpsewhich cont-en.xml`.chomp)

root=REXML::Document.new(src).root
en=ConTeXtSetup::Interface.parse_xml(root)

en.commands.each do |k,v|
  p k
#  puts v[0].to_html
end