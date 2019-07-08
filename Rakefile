require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'


PKG_VERSION="0.2"
DOC=["lib/tex/context/contextsetup.rb","README"]
PKG_FILES=DOC + ["Rakefile"]



spec = Gem::Specification.new do |s|
  s.platform         = Gem::Platform::RUBY
  s.summary          = "Library for accessing ConTeXt setup files (cont-??.xml)"
  s.name             = 'contextsetup'
  s.version          = PKG_VERSION
  s.email            = "patrick @nospam@ gundla.ch"
  s.files            = PKG_FILES
  s.autorequire      = 'contextsetup'
  s.require_path     = 'lib/tex/context'
  s.homepage         = "http://contextsetup.rubyforge.org/"
  s.has_rdoc         = true
  s.extra_rdoc_files = ["README"]
  s.rdoc_options    << "--main" << "README" << "--title" << "ConTeXt Setup"
  s.description      = %{ConTeXt setup library is a helper library to work with the cont-??.xml files from ConTeXt.}
end


Rake::RDocTask.new do |rd|
  rd.rdoc_files.include(DOC)
  rd.title="ConTeXt setup"
  rd.options << "-A"
  rd.options << "documented_as_accessor=RW,documented_as_reader=R"
  rd.main = "README"
  rd.rdoc_dir = "../../webpage/rdoc"
end


Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end
