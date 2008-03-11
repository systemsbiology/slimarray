module WWW
  class Mechanize
    # = Synopsis
    # This is the default (and base) class for the Pluggable Parsers.  If
    # Mechanize cannot find an appropriate class to use for the content type,
    # this class will be used.  For example, if you download a JPG, Mechanize
    # will not know how to parse it, so this class will be instantiated.
    #
    # This is a good class to use as the base class for building your own
    # pluggable parsers.
    #
    # == Example
    #  require 'rubygems'
    #  require 'mechanize'
    #
    #  agent = WWW::Mechanize.new
    #  agent.get('http://example.com/foo.jpg').class  #=> WWW::Mechanize::File
    #
    class File
      attr_accessor :uri, :response, :body, :code, :filename
      alias :header :response

      alias :content :body

      def initialize(uri=nil, response=nil, body=nil, code=nil)
        @uri, @body, @code = uri, body, code
        @response = Headers.new

        # Copy the headers in to a hash to prevent memory leaks
        if response
          response.each { |k,v|
            @response[k] = v
          }
        end

        @filename = 'index.html'

        # Set the filename
        if disposition = @response['content-disposition']
          disposition.split(/;\s*/).each do |pair|
            k,v = pair.split(/=/, 2)
            @filename = v if k.downcase == 'filename'
          end
        else
          if @uri
            @filename = @uri.path.split(/\//).last || 'index.html'
            @filename << ".html" unless @filename =~ /\./
          end
        end

        yield self if block_given?
      end

      # Use this method to save the content of this object to filename
      def save_as(filename = nil)
        if filename.nil?
          filename = @filename
          number = 1
          while(::File.exists?(filename))
            filename = "#{@filename}.#{number}"
            number += 1
          end
        end

        ::File::open(filename, "wb") { |f|
          f.write body
        }
      end

      alias :save :save_as
    end

    # = Synopsis
    # This is a pluggable parser that automatically saves every file
    # it encounters.  It saves the files as a tree, reflecting the
    # host and file path.
    #
    # == Example to save all PDF's
    #  require 'rubygems'
    #  require 'mechanize'
    #
    #  agent = WWW::Mechanize.new
    #  agent.pluggable_parser.pdf = WWW::Mechanize::FileSaver
    #  agent.get('http://example.com/foo.pdf')
    #
    class FileSaver < File
      attr_reader :filename

      def initialize(uri=nil, response=nil, body=nil, code=nil)
        super(uri, response, body, code)
        path = uri.path.empty? ? 'index.html' : uri.path.gsub(/^[\/]*/, '')
        path += 'index.html' if path =~ /\/$/

        split_path = path.split(/\//)
        filename = split_path.length > 0 ? split_path.pop : 'index.html'
        joined_path = split_path.join(::File::SEPARATOR)
        path = if joined_path.empty?
          uri.host
        else
          "#{uri.host}#{::File::SEPARATOR}#{joined_path}"
        end

        @filename = "#{path}#{::File::SEPARATOR}#{filename}"
        FileUtils.mkdir_p(path)
        save_as(@filename)
      end
    end

    # = Synopsis
    # This class is used to register and maintain pluggable parsers for
    # Mechanize to use.
    #
    # A Pluggable Parser is a parser that Mechanize uses for any particular
    # content type.  Mechanize will ask PluggableParser for the class it
    # should initialize given any content type.  This class allows users to
    # register their own pluggable parsers, or modify existing pluggable
    # parsers.
    #
    # PluggableParser returns a WWW::Mechanize::File object for content types
    # that it does not know how to handle.  WWW::Mechanize::File provides
    # basic functionality for any content type, so it is a good class to
    # extend when building your own parsers.
    # == Example
    # To create your own parser, just create a class that takes four
    # parameters in the constructor.  Here is an example of registering
    # a pluggable parser that handles CSV files:
    #  class CSVParser < WWW::Mechanize::File
    #    attr_reader :csv
    #    def initialize(uri=nil, response=nil, body=nil, code=nil)
    #      super(uri, response, body, code)
    #      @csv = CSV.parse(body)
    #    end
    #  end
    #  agent = WWW::Mechanize.new
    #  agent.pluggable_parser.csv = CSVParser
    #  agent.get('http://example.com/test.csv')  # => CSVParser
    # Now any page that returns the content type of 'text/csv' will initialize
    # a CSVParser and return that object to the caller.
    #
    # To register a pluggable parser for a content type that pluggable parser
    # does not know about, just use the hash syntax:
    #  agent.pluggable_parser['text/something'] = SomeClass
    # 
    # To set the default parser, just use the 'defaut' method:
    #  agent.pluggable_parser.default = SomeClass
    # Now all unknown content types will be instances of SomeClass.
    class PluggableParser
      CONTENT_TYPES = {
        :html => 'text/html',
        :pdf  => 'application/pdf',
        :csv  => 'text/csv',
        :xml  => 'text/xml',
      }

      attr_accessor :default

      def initialize
        @parsers = { CONTENT_TYPES[:html] => Page }
        @default = File
      end

      def parser(content_type)
        content_type.nil? ? default : @parsers[content_type] || default
      end

      def register_parser(content_type, klass)
        @parsers[content_type] = klass
      end

      def html=(klass)
        register_parser(CONTENT_TYPES[:html], klass)
      end

      def pdf=(klass)
        register_parser(CONTENT_TYPES[:pdf], klass)
      end

      def csv=(klass)
        register_parser(CONTENT_TYPES[:csv], klass)
      end

      def xml=(klass)
        register_parser(CONTENT_TYPES[:xml], klass)
      end

      def [](content_type)
        @parsers[content_type]
      end

      def []=(content_type, klass)
        @parsers[content_type] = klass
      end
    end

    class Headers < Hash
      def [](key)
        super(key.downcase)
      end
      def []=(key, value)
        super(key.downcase, value)
      end
    end
  end
end
