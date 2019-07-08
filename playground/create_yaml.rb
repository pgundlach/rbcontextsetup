#!/usr/bin/env ruby


$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require 'yaml'
require 'fileutils'
require 'tex/context/contextsetup'

infile=`kpsewhich cont-en.xml`.chomp
out="../test/"