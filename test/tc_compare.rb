#!/usr/bin/env ruby

$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require 'tex/context/contextsetup'
require 'test/unit'

$interface=ConTeXtSetup::Interface.parse_xml(REXML::Document.new(File.read("testsetup-en.xml")).root)

class TestComparison < Test::Unit::TestCase
  def root(src)
    REXML::Document.new(src).root
  end
  # include ConTeXtSetup
  def setup
    @interface=ConTeXtSetup::Interface.new
  end
  def test_triplet
    src=%{<cd:triplet xmlns:cd="http://www.pragma-ade.com/commands" list='yes'/>}
    xmltriplet=ConTeXtSetup::Triplet.parse_xml(root(src),@interface)
    t=ConTeXtSetup::Triplet.new(@interface)
    t.list=true
    assert_equal(xmltriplet,t)
  end
  def test_keywords
    src=%{<cd:keywords xmlns:cd="http://www.pragma-ade.com/commands"><cd:constant type="cd:name"/></cd:keywords>}
    k_src=ConTeXtSetup::Keywords.parse_xml(root(src),@interface)
    k=ConTeXtSetup::Keywords.new(@interface)
    k.keywords=["cd:name"]
    assert_equal(k_src, k)
    
    # more complex
    src=%{<cd:keywords xmlns:cd="http://www.pragma-ade.com/commands" optional="yes">
			<cd:constant type="rgb" default="yes"/>
			<cd:constant type="cmyk"/>
			<cd:constant type="gray"/>
			<cd:constant type="s"/>
		</cd:keywords>
		}
    k_src=ConTeXtSetup::Keywords.parse_xml(root(src),@interface)
    k=ConTeXtSetup::Keywords.new(@interface)
    k.keywords=["rgb","cmyk","gray","s"]
    k.default=0
    k.optional=true
		assert_equal(k_src, k)
  end
  def test_parameter
    src=%{<cd:parameter xmlns:cd="http://www.pragma-ade.com/commands" name="bodyfont">
			<cd:constant type="5pt"/>
			<cd:constant type="..."/>
			<cd:constant type="12pt"/>
			<cd:constant type="small"/>
			<cd:constant type="big"/>
		</cd:parameter>}
		p_src=ConTeXtSetup::Parameter.parse_xml(root(src),@interface)
		p=ConTeXtSetup::Parameter.new(@interface)
		p.name="bodyfont"
		p.list=["5pt","...","12pt","small","big"]
		assert_equal(p, p_src)
  end
  def test_inherit
    src=%{<cd:inherit xmlns:cd="http://www.pragma-ade.com/commands" name="setupframed"/>}
    i_src=ConTeXtSetup::Inherit.parse_xml(root(src),@interface)
    i=ConTeXtSetup::Inherit.new(@interface)
    i.name="setupframed"
    assert_equal(i, i_src)
  end
  def test_content
    src=%{<cd:content xmlns:cd="http://www.pragma-ade.com/commands"/>}
    c_src=ConTeXtSetup::Content.parse_xml(root(src),@interface)
    c=ConTeXtSetup::Content.new(@interface)
    assert_equal(c,c_src)
  end
  def test_reference
    src=%{<cd:reference xmlns:cd="http://www.pragma-ade.com/commands" optional="yes" list="yes"/>}
    r_src=ConTeXtSetup::Reference.parse_xml(root(src),@interface)
    r=ConTeXtSetup::Reference.new(@interface)
    r.list=true
    r.optional=true
    assert_equal(r, r_src)
  end
  def test_word
    src=%{<cd:word xmlns:cd="http://www.pragma-ade.com/commands" list="yes"/>}
    r_src=ConTeXtSetup::Word.parse_xml(root(src),@interface)
    r=ConTeXtSetup::Word.new(@interface)
    r.list=true
    assert_equal(r, r_src)
  end
  def test_index
    src=%{<cd:index xmlns:cd="http://www.pragma-ade.com/commands" list="yes"/>}
    r_src=ConTeXtSetup::Index.parse_xml(root(src),@interface)
    r=ConTeXtSetup::Index.new(@interface)
    r.list=true
    assert_equal(r, r_src)
  end
  def test_position
    src=%{<cd:position xmlns:cd="http://www.pragma-ade.com/commands" list="yes"/>}
    r_src=ConTeXtSetup::Position.parse_xml(root(src),@interface)
    r=ConTeXtSetup::Position.new(@interface)
    r.list=true
    assert_equal(r, r_src)
  end
  def test_assignments
    # inherit
    src=%{<cd:assignments xmlns:cd="http://www.pragma-ade.com/commands" optional="yes" list="yes">
  				<cd:inherit name="setupfillinlines"/>
  			</cd:assignments>}
  	a_src=ConTeXtSetup::Assignments.parse_xml(root(src),@interface)
  	a=ConTeXtSetup::Assignments.new(@interface)
  	i=ConTeXtSetup::Inherit.new(@interface)
  	i.name="setupfillinlines"
  	a.parameters << i
  	a.list=true
  	a.optional=true
  	assert_equal(a.parameters[0], i)
  	assert_equal(a, a_src)
  end
  def test_all_xml
    src=File.read("testsetup-en.xml")
    i=ConTeXtSetup::Interface.parse_xml(root(src))
    assert_equal(i, i)
  end
  def test_complex
    dcg=$interface.commands["definecolorgroup"][0]
    assert_equal(dcg, dcg)
  end
end