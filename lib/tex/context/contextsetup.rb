#!/usr/bin/env ruby 
# == ConTeXtSetup Library
# Example usage:
#
#    src='<cd:command name="completecombinedlist" generated="yes">
#      <cd:sequence>
#        <cd:string value="complete"/>
#        <cd:variable value="combinedlist"/>
#      </cd:sequence>
#      <cd:arguments>
#        <cd:keywords>
#          <cd:constant type="cd:name"/>
#        </cd:keywords>
#        <cd:assignments list="yes">
#          <cd:inherit name="setupcombinedlist"/>
#        </cd:assignments>
#      </cd:arguments>
#    </cd:command>'
# 
#   root = REXML::Document.new(src).root
#   i = Setup::Interface.parse_xml(root)
#   i.commands # => Hash {"completecombinedlist" => [#<Command::...>] }
#   cmd = i.commands["completecombinedlist"][0]  # variant no 0
#   cmd.to_html  # <table ...> ... </table>
#   # You can also compare two commands (which compares all its arguments)
#   cmd_a == cmd_b # true/false
# == Other
# Documentation: http://contextsetup.rubyforge.org
# Project page: http://rubyforge.org/projects/contextsetup/

require 'rexml/document'


# See ConTeXtSetup::Interface for documentation.
module ConTeXtSetup
  
  # If I can't understand a command from cont-en.xml, I raise
  # this exception.
  class CommandParseException < RuntimeError ; end

  # The parse_xml interface for the helper classes. 
  class SetupXML
    class << self
      def parse_xml(elt,interface)
        t=new(interface)
        t.parse_xml(elt)
        return t
      end
      def tag_method(*names)
        names.each do |sym|
          class_eval %{
            def #{sym}(options={},&block)
              tmp=""
              options.each do |key,value| 
                tmp << " " + key.to_s + "='" + value.to_s +  "'"
              end
              "<#{sym}" + tmp.to_s + ">" + (block ? block.call.to_s : "") + "</#{sym}>"
            end
          }
        end
      end
    end
    
    tag_method :td, :table, :tr, :span, :strong
    def initialize
    end
    
    def parse_xml(elt)
    end

  end

  # Main class for parsing the cont-??.xml file. Just feed the root
  # element (cd:interface) or a command element (cd:document) into the
  # class method parse_xml. These elements must be of type
  # REXML::Element.
  #
  class Interface   < SetupXML
    class << self
      def parse_xml(elt)
        t=new
        t.parse_xml(elt)
        return t
      end
    end
    # The language of the interface as a String. Default is "en"
    attr_accessor :language
    # The version number of the interface definition. Only set if is
    # read from xml
    attr_accessor :version
    # Hash of the commands. The key is the name of the command +
    # start if it is an environment. The value is an array of the
    # variants of the command. I.e. the first element of the
    # array is variant number one, the second number two etc.
    attr_accessor :commands
    # The resolve parts
    attr_accessor :defines
    # This string contains the error messages if something goes wrong.
    attr_reader :error_messages
    def parse_xml(elt)  # :nodoc: 
      case elt.name
      when "interface"
        # one or more <command ...> 
        @language = elt.attributes["language"]
        @version  = elt.attributes["version"]
        elt.each_element do |cmd_or_define|
          case cmd_or_define.name
          when "command"
            add_command(cmd_or_define)
          when "define"
            d=Define.parse_xml(cmd_or_define,self)
            @defines[d.name]=d
          else
            raise "not implemented: interface/#{cmd_or_define.name}"
          end
        end
      when "command"
        add_command(elt)
      else
        raise ArgumentError, "The top element for parse_xml should be 'interface' or 'command', but is '#{elt.name}'"
      end
    end
    
    # Dummy parameter is only for a nicer piece of code in another place
    def initialize(dummy=nil)
      @language="en"
      @version=nil
      @commands={}
      @defines={}
      @error_messages = ""
    end
    
    def ==(other)
      Interface===other && @commands == other.commands
    end
    
    private
    
    # Put an array with the variants of each command (see placeregister for an example)
    # in a hash (@commands) where the key is the name of the command and the value
    # is the array.  cmd_elt is a REXML::Element which needs to get parsed.
    # The XML can be currupt. If this is the case the command can obviously not be included
    # in the list of the commands. But how should the bug report be? Perhaps there 
    # should be an error string which the user can view after the library finishes.
    def add_command(cmd_elt)
      begin
        c=Command.parse_xml(cmd_elt,self)
        # c is now a Command. c.cmd_name(false) is the name of the command such  as
        # "color" or "startcolor"
        #
        # every value of the @command hash has an arry as its argument
        # if there is no array yet, the following adds a default empty array to 
        # the entry of the command
        ary=@commands[c.cmd_name(false)] ||= []
        # the default variant is 1
        ary[c.variant - 1]=c
      rescue CommandParseException => e
        @error_messages <<  "broken command: #{e} inside\n#{cmd_elt}\n----------------------------\n"
      end
    end
  end
  
  class Define < SetupXML
    attr_accessor :name, :keywords
    def parse_xml(elt) # :nodoc:
      @name=elt.attributes["name"]
      elt.each_element do |constant|
        @keywords << constant.attributes["type"]
      end
    end
    def initialize(interface)
      @interface=interface
      @name=nil
      @keywords = []
    end
  end
  # Represents a single command with a sequence (the name of the command) and an argument list.
  class Command     < SetupXML
    attr_accessor :sequence, :arguments,:environment, :generated, :name, :file, :variant

    def parse_xml(elt) # :nodoc:
      @name = elt.attributes["name"]
      @file = elt.attributes["file"]
      @variant = (elt.attributes["variant"] && elt.attributes["variant"].to_i ) || 1
      @environment = elt.attributes["type"]        == "environment"
      @generated   = elt.attributes["generated"]   == "yes"
      
      @sequence = Sequence.parse_xml(elt.elements[1],@interface)
      arguments=elt.elements[2]

      # if this is a macro without arguments, we can return now and not parse any arguments
      return unless arguments

      disp_table = { 
        "keywords"    => ConTeXtSetup::Keywords,
        "triplet"     => ConTeXtSetup::Triplet,
        "assignments" => ConTeXtSetup::Assignments,
        "content"     => ConTeXtSetup::Content,
        "reference"   => ConTeXtSetup::Reference,
        "word"        => ConTeXtSetup::Word,
        "nothing"     => ConTeXtSetup::Nothing,
        "file"        => ConTeXtSetup::File,
        "csname"      => ConTeXtSetup::Csname,
        "index"       => ConTeXtSetup::Index,
        "position"    => ConTeXtSetup::Position,
        "displaymath" => ConTeXtSetup::Displaymath,
        "tex"         => ConTeXtSetup::TeX,
      } 
      arguments.each_element do |arg|
        if disp_table.has_key?(arg.name)
            @arguments << disp_table[arg.name].send(:parse_xml,arg,@interface)
        else
          raise "unknown argument: #{arg.name}"
        end
      end
    end

    def initialize(interface)
      @interface=interface
      @name=nil
      @file=nil
      @variant=1
      @environment=false
      @generated=false
      @sequence=nil
      @arguments=[]
      @inteface=interface
      @enum=%w( first second third )
      super()
    end
    # Return the number of arguments the command takes. If with_optional is false, 
    # return only the number of mandatory arguments.
    def no_of_arguments(with_optional=true)
      tmp=@arguments.reject do |arg|
        unless arg.optional?
          true unless with_optional
        else
          false
        end
      end
      tmp.size
    end
    # Return the name of the command, translated in the current
    # interface's language. Included is the start prefix if the
    # command is an environment and the backslash if
    # <em>with_backslash</em> is set to true (the default).
    def cmd_name(with_backslash=true)
      backslash= with_backslash ? "\\" : ""
      tmp=environment ? "#{backslash}start" : backslash
      tmp << @sequence.cmd_name
      return tmp
    end
    # Return the name of the command, translated in the current
    # interface's language. Included is the start prefix if the
    # command is an environment and the backslash if
    # <em>with_backslash</em> is set to true (the default).
    def cmd_name_html(with_backslash=true)
      tmp=environment ? "\\start" : "\\"
      tmp << @sequence.cmd_name_html
      return tmp
    end
    # Return true if the command name has a variable part in it, such as \placecombinedlist.
    def has_variable?
      @sequence.has_variable?
    end
    # Return HTML representation of the command.
    def to_html
      first_line = []
      details    = []
      @arguments.each_with_index do |arg,i|
        cls=@enum[ i % @enum.size]
        opt_or_not_opt = arg.optional? ? span(:class => "optional") { arg.to_html(false) } : arg.to_html(false)
        first_line << span(:class => cls) {  opt_or_not_opt }
        details    << arg.to_html(true, cls)
      end

      table(:class  =>  "cmd", :cellspacing => "4", :cellpadding => "2") {
        tr {  
          td(:colspan => "2", "class" => "cmd") { cmd_name_html(true) + first_line.to_s }  
        } + 
        details.to_s
      }
    end
    # Compare the command with _other_. The comparison is based on the arguments,
    # the environment status, sequence and the generated status.
    def ==(other)
      return false unless Command===other
      @sequence == other.sequence && @environment==other.environment &&
       @arguments == other.arguments && @generated==other.generated
    end
    # Return a textual representation for a snippet that can be used
    # by the TextMate text editor (see http://macromates.com/).
    def to_tm_snippet
      tmp = cmd_name(true) << " "
      counter=0
      @arguments.each_with_index do |arg,i|
        x = arg.optional? ? "${#{counter += 1}:#{arg.to_tm_snippet( counter += 1 )}}" : "#{arg.to_tm_snippet(counter += 1 )}"
        tmp << x
      end
      tmp = tmp.rstrip << "\n$#{counter + 1}"
      tmp << "\n\\stop#{sequence.cmd_name  }" if@environment
      tmp
    end
  end
  # The visible name of a command. 
  class Sequence    < SetupXML
    # _sequence_ is an Array of Arrays. Example: [[:string, "place"],[:variable, "combinedlist"].
    attr_accessor :sequence
    def initialize(interface)
      @interface=interface
      @sequence=[]
    end
    def parse_xml(sequence) # :nodoc: 
      sequence.each_element do |elt| 
        case elt.name
        when "string"
          @sequence << [:string,   elt.attributes["value"]]
        when "variable"
          @sequence << [:variable, elt.attributes["value"]]
        else
          raise "internal error"
        end
      end
      # Return html representation of the sequence, not including a
      # backslash or the start-prefix for environments.
    end
    def to_html # :nodoc:
      tmp=@sequence.collect do |type,name|
        case type
        when :string
          name
        when :variable
          "<i>#{name}</i>"
        end
      end
      tmp.to_s
    end
    
    # Return true if the command name has a variable part in it, such as \placecombinedlist.
    def has_variable?
      @sequence.any? do |type,name|
        type==:variable
      end
    end
    # Return the name of the command, without backslash and without start if it is an environment
    def cmd_name
      @sequence.collect do |type,name|
        name
      end.to_s
    end
    # Return the name as html, without backslash and without start if it is an environment 
    def cmd_name_html
      @sequence.collect do |type,name|
        case type
        when :string
          name
        when :variable
          "<i>#{name}</i>"
        else
          raise "internal error"
        end
      end.to_s
    end
  end
  # An interface for all the parameters (Position, TeX, Csname, Word, ...)
  class Param       < SetupXML
    def initialize(interface)
      @interface=interface
    end
    def opt(what)
      optional? ? span(:class => "optional") { what } :  what
    end
    def sanitize_html(text)
      text.gsub(/cd:([a-zA-Z]+)/,'<i>\1</i>')
    end
    def optional?
      if  self.respond_to?(:optional) 
        self.optional
      else
        false
      end
    end
    def to_html(detail=true,cls="first") # :nodoc:
      head=show
      if detail
        tr { 
          td(:class => cls) { head } + td(:class => cls)
        }
      else
        head
      end
    end
    private
    def show
      raise ScriptError, "must be subclassed"
    end
  end

  class Assignments < Param
    attr_accessor :list,:parameters, :optional
    def parse_xml(elt) # :nodoc:
      @list     = elt.attributes["list"]     == "yes"
      @optional = elt.attributes["optional"] == "yes"
      elt.each_element do |parameter|
        case parameter.name
        when "inherit"
          @parameters << Inherit.parse_xml(parameter,@interface)
        when "parameter"
          @parameters << Parameter.parse_xml(parameter,@interface)
        else
          raise "not implemented yet: assignments/#{parameter.name}"
        end
      end
    end # parse_xml
    def initialize(interface)
      @interface=interface
      @optional=false
      @list=false
      @parameters=[]
    end
    def to_html(detail=true,cls="first") # :nodoc:
      head = show
      if detail
        tmp=@parameters.collect do |param|
          tr(:class => cls, :valign => "top") {
            case param
            when Parameter
              td { param.to_html(false) } + td {param.to_html(true)} 
            when Inherit
              td { head } + td { param.to_html }
            end
          } + "\n"
        end.to_s
      else
        head 
      end
    end
    def to_tm_snippet(cursor) # :nodoc: 
      if @list
        "[${#{cursor}:...,...=...,...}]"
      else
        "[${#{cursor}:...=...}"
      end
    end
    def ==(other)
      Assignments===other && @optional == other.optional && @list=other.list && @parameters==other.parameters
    end
    private
    
    def show
      @list ? "[...,...=...,...]" : "[...=...]"
    end
  end
  class Content     < Param
    attr_accessor :list
    def parse_xml(elt) # :nodoc:
      @list = elt.attributes["list"] == "yes"
    end # parse_xml
    def initialize(interface)
      @interface=interface
      @list=false
    end
    def to_html(detail=true,cls='first') # :nodoc:
      head = show
      if detail
        tr{  td(:class => cls) { head } + td(:class => cls) { "<i>text</i>" } }
      else
        head
      end
    end
    def to_tm_snippet(cursor) # :nodoc: 
      if @list
        "{${#{cursor}:...,...,...}}"
      else
        "{${#{cursor}:...}}"
      end
    end
    def ==(other)
      Content===other && @list == other.list
    end
    private

    def show
      @list ? "{...,...,...}" : "{...}"
    end

  end
  class Csname      < Param
    def to_html(detail=true,cls="first") # :nodoc:
      if detail
        ""
      else
        "\\command"
      end
    end
    def ==(other)
      ConTeXtSetup::Csname===other
    end
    def to_tm_snippet(cursor) # :nodoc: 
      "\\\\${#{cursor}:command}"
    end
  end
  class Displaymath < Param
    def to_html(detail=true,cls="first") # :nodoc:
      head=show
      if detail
        tr { 
          td(:class => cls) { head } + td(:class => cls) { "<i>formula</i>" }
        }
      else
        head
      end
    end
    def ==(other)
      ConTeXtSetup::Displaymath===other
    end
    def to_tm_snippet(cursor) # :nodoc: 
      "\\$\\$${#{cursor}:...}\\$\\$"
    end
    private
    def show
      "$$...$$"
    end
    
  end
  class File        < Param
    def to_html(detail=true,cls="first") # :nodoc:
      if detail
        tr(:class => cls, :valign => "top") { td(:class => 'cmd') { "..." } + td { "<i>file</i>" } }
      else
        "..."
      end
    end
    def to_tm_snippet(cursor) # :nodoc: 
      "${#{cursor}:<filename>}"
    end
  end
  class Index       < Param
    attr_accessor :list
    def parse_xml(elt) # :nodoc:
      @list = elt.attributes["list"] == "yes"
    end
    def initialize(interface)
      @interface=interface
      @list=false
    end
    def to_tm_snippet(cursor) # :nodoc: 
      if @list
        "{${#{cursor}:...+...+...}}"
      else
        "{${#{cursor}:...}}"
      end
    end
    def ==(other)
      ConTeXtSetup::Index===other && @list==other.list
    end
    private

    def show
      @list ? "{...+...+...}" : "{...}"
    end
  end # 
  class Inherit     < Param
    attr_accessor :name
    def parse_xml(elt) # :nodoc:
      @name=elt.attributes["name"]
    end # parse_xml
    def initialize(interface)
      @interface=interface
      @name=nil
    end
    def to_html
      "see also #{@name}"
    end
    def ==(other)
      Inherit===other && @name==other.name
    end
  end
  class Keywords    < Param
    attr_accessor :optional,:keywords, :default, :list
    def parse_xml(keywords)
      @optional = keywords.attributes['optional']=="yes"
      @list     = keywords.attributes['list']=="yes"
      keywords.each_element do |constant_or_resolve|
        case constant_or_resolve.name
        when "constant"
          # we don't want to add nils to the @keywords array
          if att_t = constant_or_resolve.attributes["type"]
            @keywords << att_t
          end
        when "resolve"
          if idef = @interface.defines[constant_or_resolve.attributes["name"]]
            @keywords = idef.keywords
          else
            raise CommandParseException, "unhandled resolve: '#{constant_or_resolve.attributes["name"]}'"
          end
        else
          raise CommandParseException, "unknown element in cd:keywords. One of 'constant' or 'resolve' expected"
        end
        # we mark defaults, of course!
        if constant_or_resolve.attributes["default"]=="yes"
          @default=@keywords.size - 1
        end
      end
      if @keywords.empty?
        raise CommandParseException, "no attributes 'type' in cd:constant or 'name' in cd:resolve present"
      end
    end # parse_xml
    def initialize(interface)
      @interface=interface
      @optional=false
      @list=false
      @default=nil
      @keywords=[]
    end
    def to_html(detail=true,cls="first") # :nodoc:
      head=@list ? "[...,...,...]" : "[...]"
      if detail
        # create list
        lst=[]
        @keywords.each_with_index { |kw, i|
          lst << (@default==i ? strong { kw } : kw )
        }  
        tr { td(:class => cls) { head } + td(:class => cls) { sanitize_html(lst.join(" ")) } }
      else
        head
      end
    end
    def to_tm_snippet(cursor) # :nodoc: 
      if @list
        "[${#{cursor}:...,...,...}]"
      else
        "[${#{cursor}:...}]"
      end
    end
    # Return true if the two objects are the same. Comparison is based on the 
    # attributes 'list', 'default', 'optional' and 'keywords'.
    def ==(other)
      return false unless Keywords===other
      other.optional == @optional && other.keywords == @keywords && 
        other.default == @default && other.list == @list
    end
  end
  class Nothing     < Param
    attr_accessor :separator
    def parse_xml(elt) # :nodoc:
      if elt.attributes["separator"]=="backslash"
        @separator = "\\\\"
      end
    end
    def initialize(interface)
      @interface=interface
      @separator=nil
    end
    def to_html(detail=true,cls='first') # :nodoc:
      if detail
        tr(:class => cls, :valign => "top" ) { 
          td { "..." } + td { "<i>text</i>" }
        }
      else
        "#{@separator}..."
      end
    end
    def to_tm_snippet(cursor) # :nodoc: 
      " #{@separator} ${#{cursor}:...}"
    end
    def ==(other)
      Nothing===other && other.separator==@separator
    end
  end
  class Parameter   < Param
    attr_accessor :name, :list
    def parse_xml(elt) # :nodoc:
      @name=elt.attributes["name"]
      elt.each_element do |elt|
        att_name=elt.attributes["name"]
        case elt.name
        when "constant"
          @list << elt.attributes["type"]
        when "resolve"
          if idef = @interface.defines[att_name]
            @list = idef.keywords
          else
            raise CommandParseException, "unhandled resolve: '#{att_name}'"
          end
        else  
          raise "not implemented yet: Parameter/#{elt.name}"
        end
      end
    end # parse_xml
    def initialize(interface)
      @interface=interface
      @name=nil
      @list=[]
    end
    def to_html(detail=true) # :nodoc:
      if detail
        sanitize_html @list.join(" ")
      else
        @name
      end
      
    end
    def ==(other)
      Parameter===other && @name==other.name && @list==other.list
    end
  end
  class Position    < Param
    attr_accessor :list
    def parse_xml(elt) # :nodoc:
      @list = elt.attributes["list"] == "yes"
    end
    def initialize(interface)
      @interface=interface
      @list=false
    end
    def to_html(detail=true,cls="first") # :nodoc:
      head=show
      if detail
        tr { 
          td(:class => cls) { head } + td(:class => cls) { "<i>number</i>, <i>number</i>"}
        }
      else
        head
      end
    end
    def to_tm_snippet(cursor) # :nodoc: 
      if @list
        "(${#{cursor}:...,...})"
      else
        "(${#{cursor}:..})"
      end
    end
    def ==(other)
      ConTeXtSetup::Position===other && @list==other.list
    end
    
    private

    def show
      @list ? "(...,...)" : "(..)"
    end
  end
  class Reference   < Param
    attr_accessor :optional, :list
    def parse_xml(elt) # :nodoc:
      @optional = elt.attributes["optional"] == "yes"
      @list     = elt.attributes['list']=="yes"
    end
    def initialize(interface)
      @interface=interface
      @optional=false
    end
    def to_tm_snippet(cursor) # :nodoc: 
      if @list
        "[${#{cursor}:ref,ref,..}]"
      else
        "[${#{cursor}:ref}]"
      end
    end
    def ==(other)
      ConTeXtSetup::Reference===other && @optional == other.optional && @list==other.list
    end
    private
    def show
      @list ? "[ref,ref,...]" : "[ref]"
    end
    
  end
  class TeX         < Param
    # If set, usually set to \\ (backslash)
    attr_accessor :separator
    # The command that all this is about (without any backslashes)
    attr_accessor :command
    def parse_xml(elt) # :nodoc:
      if elt.attributes["separator"]
        @separator = "\\\\"
      end
      @command   = elt.attributes["command"]
    end
    def initialize(interface)
      @interface=interface
      @separator=nil
      @command=nil
    end
    def to_html(detail=true,cls='first') # :nodoc:
      if detail
        ""
      else
        "#{@separator}\\#{@command}"
      end
    end
    def to_tm_snippet(cursor) # :nodoc: 
      "#{@separator}\\#{@command}"
    end
    def ==(other)
      ConTeXtSetup::TeX===other && @separator==other.separator && @command == other.command
    end
  end
  class Triplet     < Param
    attr_accessor :list
    def parse_xml(elt) # :nodoc:
      @list=elt.attributes["list"]=="yes"
    end
    def initialize(interface)
      @interface=interface
      @list=false
    end
    # Return true if the two objects are the same. Comparison is based on the attribute 'list'.
    def ==(other)
      return false unless Triplet===other
      other.respond_to?(:list) && self.list==other.list 
    end
    def to_tm_snippet(cursor) # :nodoc: 
      "[${#{cursor}:x:y:z=...}]"
    end
    
    private
    
    def show
      "[x:y:z=,...]"
    end
  end
  class Word        < Param
    attr_accessor :list
    def parse_xml(elt) # :nodoc:
      @list = elt.attributes["list"] == "yes"
    end
    def initialize(interface)
      @interface=interface
      @list=false
    end
    def to_tm_snippet(cursor) # :nodoc: 
      "{${#{cursor}:... ...}}"
    end
    def to_html(detail=true,cls="first") # :nodoc:
      # this is a hack! cd:word only appears with one argument, so the second td looks ugly
      # TODO: this should be corrected in Command.to_html
      head="{... ...}"
      if detail
        tr { 
          td(:class => cls) { head }
        }
      else
        head
      end
    end
    def ==(other)
      ConTeXtSetup::Word===other && @list==other.list
    end
  end
end

