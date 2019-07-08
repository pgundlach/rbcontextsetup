# The ConTeXt Setup library (README)

ConTeXt is a TeX macro package. The high-level commands that are defined
by this package are documented in several xml-files, one for each interface
language. The main file is the english definition in cont-en.xml. This library
gives you a high level access to these definition files.

#  Roadmap

##  Usage

Just look at an example program:

```
   #!/usr/bin/env ruby

   require 'rubygems'
   gem 'contextsetup'
   # or
   # require 'tex/context/contextsetup'

   src=File.read(`kpsewhich cont-en.xml`.chomp)
   root=REXML::Document.new(src).root

   en=ConTeXtSetup::Interface.parse_xml(root)
```

##  Installation

## Other Stuff

Author:: Patrick Gundlach <patrick@nospam@gundla.ch>
Project Page::  http://rubyforge.org/projects/contextsetup/
Homepage:: (Documentation) http://contextsetup.rubyforge.org/
License:: MIT License (see below)

##  License
Copyright (c) 2006 Patrick Gundlach

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.