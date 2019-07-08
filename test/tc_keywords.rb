#!/usr/bin/env ruby

require "test/unit"
$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require "tex/context/contextsetup"

class TestKeywords < Test::Unit::TestCase
  def test_broken_inside_keywords
    src=%q{<cd:command xmlns:cd="http://www.pragma-ade.com/commands" name="resettextcontent" file="page-txt.tex">
  <cd:sequence>
    <cd:string value="resettextcontent"/>
  </cd:sequence>
  <cd:arguments>
    <cd:keywords optional="yes">
      <cd:foo/>
      <cd:constant name="lefttext"/>
      <cd:constant name="middletext"/>
      <cd:constant name="righttext"/>
    </cd:keywords>
  </cd:arguments>
</cd:command>
    }
    root=REXML::Document.new(src).root
    i=ConTeXtSetup::Interface.parse_xml(root)
    assert(i.error_messages.size > 0, "Failure message.")
  end
  
  def test_valid_keywords
    src=%q{<cd:command xmlns:cd="http://www.pragma-ade.com/commands" name="resettextcontent" file="page-txt.tex">
  <cd:sequence>
    <cd:string value="resettextcontent"/>
  </cd:sequence>
  <cd:arguments>
    <cd:keywords optional="yes">
      <cd:constant type="lefttext"/>
      <cd:constant type="middletext"/>
      <cd:constant type="righttext"/>
    </cd:keywords>
  </cd:arguments>
</cd:command>
    }
    root=REXML::Document.new(src).root
    i=ConTeXtSetup::Interface.parse_xml(root)
    assert(i.error_messages.size == 0, "Failure message.")
  end

  def test_broken_resolve
    src=%q{<cd:command xmlns:cd="http://www.pragma-ade.com/commands" name="resettextcontent" file="page-txt.tex">
  <cd:sequence>
    <cd:string value="resettextcontent"/>
  </cd:sequence>
  <cd:arguments>
    <cd:keywords>
      <cd:resolve name="layout-v"/>
    </cd:keywords>
  </cd:arguments>
</cd:command>
    }
    root=REXML::Document.new(src).root
    i=ConTeXtSetup::Interface.parse_xml(root)
    assert(i.error_messages.size > 0, "Failure message.")
  end

end