# Original Code: 
# Copyright (c) 2005 by Michael Neumann (mneumann@ntecs.de) 
#
# New Code:
# Copyright (c) 2006 by Aaron Patterson (aaronp@rubyforge.org) 
#
# Please see the LICENSE file for licensing.
#

# required due to the missing get_fields method in Ruby 1.8.2
unless RUBY_VERSION > "1.8.2"
  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), "mechanize", "net-overrides")
end

require 'net/http'
require 'net/https'

# Monkey patch for ruby 1.8.4
unless RUBY_VERSION > "1.8.4"
module Net # :nodoc:
  class HTTPResponse # :nodoc:
    CODE_TO_OBJ['500'] = HTTPInternalServerError
  end
end
end

require 'uri'
require 'webrick/httputils'
require 'zlib'
require 'stringio'
require 'mechanize/monkey_patch'
require 'mechanize/cookie'
require 'mechanize/errors'
require 'mechanize/pluggable_parsers'
require 'mechanize/form'
require 'mechanize/form_elements'
require 'mechanize/history'
require 'mechanize/list'
require 'mechanize/page'
require 'mechanize/page_elements'
require 'mechanize/inspect'

module WWW

# = Synopsis
# The Mechanize library is used for automating interaction with a website.  It
# can follow links, and submit forms.  Form fields can be populated and
# submitted.  A history of URL's is maintained and can be queried.
#
# == Example
#  require 'rubygems'
#  require 'mechanize'
#  require 'logger'
#  
#  agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
#  agent.user_agent_alias = 'Mac Safari'
#  page = agent.get("http://www.google.com/")
#  search_form = page.forms.name("f").first
#  search_form.fields.name("q").value = "Hello"
#  search_results = agent.submit(search_form)
#  puts search_results.body
class Mechanize
  ##
  # The version of Mechanize you are using.
 
  VERSION = '0.6.7'

  ##
  # User Agent aliases
  AGENT_ALIASES = {
    'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    'Windows IE 7' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
    'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
    'Mac Safari' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418 (KHTML, like Gecko) Safari/417.9.3',
    'Mac FireFox' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.3) Gecko/20060426 Firefox/1.5.0.3',
    'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
    'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
    'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
    'Mechanize' => "WWW-Mechanize/#{VERSION} (http://rubyforge.org/projects/mechanize/)"
  }

  attr_accessor :cookie_jar
  attr_accessor :log
  attr_accessor :open_timeout, :read_timeout
  attr_accessor :user_agent
  attr_accessor :watch_for_set
  attr_accessor :ca_file
  attr_accessor :key
  attr_accessor :cert
  attr_accessor :pass
  attr_accessor :redirect_ok
  attr_accessor :keep_alive_time
  attr_accessor :keep_alive
  attr_accessor :conditional_requests

  attr_reader :history
  attr_reader :pluggable_parser

  alias :follow_redirect? :redirect_ok

  def initialize
    # attr_accessors
    @cookie_jar     = CookieJar.new
    @log            = nil
    @open_timeout   = nil
    @read_timeout   = nil
    @user_agent     = AGENT_ALIASES['Mechanize']
    @watch_for_set  = nil
    @ca_file        = nil
    @cert           = nil # OpenSSL Certificate
    @key            = nil # OpenSSL Private Key
    @pass           = nil # OpenSSL Password
    @redirect_ok    = true # Should we follow redirects?
    
    # attr_readers
    @history        = WWW::Mechanize::History.new
    @pluggable_parser = PluggableParser.new

    # Basic Auth variables
    @user           = nil # Basic Auth User
    @password       = nil # Basic Auth Password

    # Proxy settings
    @proxy_addr     = nil
    @proxy_pass     = nil
    @proxy_port     = nil
    @proxy_user     = nil

    @conditional_requests = true

    # Connection Cache & Keep alive
    @connection_cache = {}
    @keep_alive_time  = 300
    @keep_alive       = true

    yield self if block_given?
  end

  def max_history=(length); @history.max_size = length; end
  def max_history; @history.max_size; end

  # Sets the proxy address, port, user, and password
  def set_proxy(addr, port, user = nil, pass = nil)
    @proxy_addr, @proxy_port, @proxy_user, @proxy_pass = addr, port, user, pass
  end

  # Set the user agent for the Mechanize object.
  # See AGENT_ALIASES
  def user_agent_alias=(al)
    self.user_agent = AGENT_ALIASES[al] || raise("unknown agent alias")
  end

  # Returns a list of cookies stored in the cookie jar.
  def cookies
    @cookie_jar.to_a
  end

  # Sets the user and password to be used for basic authentication.
  def basic_auth(user, password)
    @user = user
    @password = password
  end

  # Fetches the URL passed in and returns a page.
  def get(url, referer=nil, &block)
    cur_page = referer || current_page ||
                    Page.new( nil, {'content-type'=>'text/html'})

    # fetch the page
    abs_uri = to_absolute_uri(url, cur_page)
    request = fetch_request(abs_uri)
    page = fetch_page(abs_uri, request, cur_page, &block)
    add_to_history(page)
    page
  end

  # Fetch a file and return the contents of the file.
  def get_file(url)
    get(url).body
  end


  # Clicks the WWW::Mechanize::Link object passed in and returns the
  # page fetched.
  def click(link)
    referer =
      begin
        link.page
      rescue
        nil
      end
    uri = to_absolute_uri(
      link.attributes['href'] || link.attributes['src'] || link.href,
      referer || current_page()
    )
    get(uri, referer)
  end

  # Equivalent to the browser back button.  Returns the most recent page
  # visited.
  def back
    @history.pop
  end

  # Posts to the given URL wht the query parameters passed in.  Query
  # parameters can be passed as a hash, or as an array of arrays.
  # Example:
  #  agent.post('http://example.com/', "foo" => "bar")
  # or
  #  agent.post('http://example.com/', [ ["foo", "bar"] ])
  def post(url, query={})
    node = Hpricot::Elem.new(Hpricot::STag.new('form'))
    node['method'] = 'POST'
    node['enctype'] = 'application/x-www-form-urlencoded'

    form = Form.new(node)
    query.each { |k,v|
      form.fields << Field.new(k,v)
    }
    post_form(url, form)
  end

  # Submit a form with an optional button.
  # Without a button:
  #  page = agent.get('http://example.com')
  #  agent.submit(page.forms.first)
  # With a button
  #  agent.submit(page.forms.first, page.forms.first.buttons.first)
  def submit(form, button=nil)
    form.add_button_to_query(button) if button
    uri = to_absolute_uri(form.action)
    case form.method.upcase
    when 'POST'
      post_form(uri, form) 
    when 'GET'
      uri.query = WWW::Mechanize.build_query_string(form.build_query)
      get(uri)
    else
      raise "unsupported method: #{form.method.upcase}"
    end
  end

  # Returns the current page loaded by Mechanize
  def current_page
    @history.last
  end

  # Returns whether or not a url has been visited
  def visited?(url)
    ! visited_page(url).nil?
  end

  # Returns a visited page for the url passed in, otherwise nil
  def visited_page(url)
    if url.respond_to? :href
      url = url.href
    end
    @history.visited_page(to_absolute_uri(url))
  end

  # Runs given block, then resets the page history as it was before. self is
  # given as a parameter to the block. Returns the value of the block.
  def transact
    history_backup = @history.dup
    begin
      yield self
    ensure
      @history = history_backup
    end
  end

  alias :page :current_page

  protected
  def set_headers(uri, request, cur_page)
    if @keep_alive
      request.add_field('Connection', 'keep-alive')
      request.add_field('Keep-Alive', keep_alive_time.to_s)
    else
      request.add_field('Connection', 'close')
    end
    request.add_field('Accept-Encoding', 'gzip,identity')
    request.add_field('Accept-Language', 'en-us,en;q0.5')
    request.add_field('Accept-Charset', 'ISO-8859-1,utf-8;q=0.7,*;q=0.7')

    unless @cookie_jar.empty?(uri)
      cookies = @cookie_jar.cookies(uri)
      cookie = cookies.length > 0 ? cookies.join("; ") : nil
      if log
        cookies.each do |c|
          log.debug("using cookie: #{c}")
        end
      end
      request.add_field('Cookie', cookie)
    end

    # Add Referer header to request
    unless cur_page.uri.nil?
      request.add_field('Referer', cur_page.uri.to_s)
    end

    # Add User-Agent header to request
    request.add_field('User-Agent', @user_agent) if @user_agent 

    # Add If-Modified-Since if page is in history
    if @conditional_requests
      if( (page = visited_page(uri)) && page.response['Last-Modified'] )
        request.add_field('If-Modified-Since', page.response['Last-Modified'])
      end
    end

    request.basic_auth(@user, @password) if @user || @password
    request
  end

  private

  def to_absolute_uri(url, cur_page=current_page())
    unless url.is_a? URI
      url = url.to_s.strip
      url = URI.parse(
              Util.html_unescape(
                url.split(/%[0-9A-Fa-f]{2}/).zip(
                  url.scan(/%[0-9A-Fa-f]{2}/)
                ).map { |x,y|
                  "#{URI.escape(x)}#{y}"
                }.join('').gsub(/%23/, '#')
              )
            )
    end

    # construct an absolute uri
    if url.relative?
      raise 'no history. please specify an absolute URL' unless cur_page.uri
      url = cur_page.uri + url
      # Strip initial "/.." bits from the path
      url.path.sub!(/^(\/\.\.)+(?=\/)/, '')
    end

    return url
  end

  def post_form(url, form)
    cur_page = form.page || current_page ||
                    Page.new( nil, {'content-type'=>'text/html'})

    request_data = form.request_data

    abs_url = to_absolute_uri(url, cur_page)
    request = fetch_request(abs_url, :post)
    request.add_field('Content-Type', form.enctype)
    request.add_field('Content-Length', request_data.size.to_s)

    log.debug("query: #{ request_data.inspect }") if log

    # fetch the page
    page = fetch_page(abs_url, request, cur_page, [request_data])
    add_to_history(page) 
    page
  end

  # Creates a new request object based on the scheme and type
  def fetch_request(uri, type = :get)
    raise "unsupported scheme" unless ['http', 'https'].include?(uri.scheme)
    if type == :get
      Net::HTTP::Get.new(uri.request_uri)
    else
      Net::HTTP::Post.new(uri.request_uri)
    end
  end

  # uri is an absolute URI
  def fetch_page(uri, request, cur_page=current_page(), request_data=[])
    raise "unsupported scheme" unless ['http', 'https'].include?(uri.scheme)

    log.info("#{ request.class }: #{ request.path }") if log

    page = nil

    cache_obj = (@connection_cache["#{uri.host}:#{uri.port}"] ||= {
      :connection         => nil,
      :keep_alive_options => {},
    })
    http_obj = cache_obj[:connection]
    if http_obj.nil? || ! http_obj.started?
      http_obj = cache_obj[:connection] =
          Net::HTTP.new( uri.host,
                  uri.port,
                  @proxy_addr,
                  @proxy_port,
                  @proxy_user,
                  @proxy_pass
                )
      cache_obj[:keep_alive_options] = {}

      # Specify timeouts if given
      http_obj.open_timeout = @open_timeout if @open_timeout
      http_obj.read_timeout = @read_timeout if @read_timeout
    end

    if uri.scheme == 'https' && ! http_obj.started?
      http_obj.use_ssl = true
      http_obj.verify_mode = OpenSSL::SSL::VERIFY_NONE
      if @ca_file
        http_obj.ca_file = @ca_file
        http_obj.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      if @cert && @key
        http_obj.cert = OpenSSL::X509::Certificate.new(::File.read(@cert))
        http_obj.key  = OpenSSL::PKey::RSA.new(::File.read(@key), @pass)
      end
    end

    # If we're keeping connections alive and the last request time is too
    # long ago, stop the connection.  Or, if the max requests left is 1,
    # reset the connection.
    if @keep_alive && http_obj.started?
      opts = cache_obj[:keep_alive_options]
      if((opts[:timeout] &&
         Time.now.to_i - cache_obj[:last_request_time] > opts[:timeout].to_i) ||
          opts[:max] && opts[:max].to_i == 1)

        log.debug('Finishing stale connection') if log
        http_obj.finish

      end
    end

    http_obj.start unless http_obj.started?

    request = set_headers(uri, request, cur_page)

    # Log specified headers for the request
    if log
      request.each_header do |k, v|
        log.debug("request-header: #{ k } => #{ v }")
      end
    end

    cache_obj[:last_request_time] = Time.now.to_i

    # Send the request
    response = http_obj.request(request, *request_data) {|response|

      body = StringIO.new
      total = 0
      response.read_body { |part|
        total += part.length
        body.write(part)
        log.debug("Read #{total} bytes") if log
      }
      body.rewind

      response.each_header { |k,v|
        log.debug("response-header: #{ k } => #{ v }")
      } if log

      content_type = nil
      unless response['Content-Type'].nil?
        data = response['Content-Type'].match(/^([^;]*)/)
        content_type = data[1].downcase unless data.nil?
      end

      response_body = 
      if encoding = response['Content-Encoding']
        case encoding.downcase
        when 'gzip'
          log.debug('gunzip body') if log
          Zlib::GzipReader.new(body).read
        else
          raise 'Unsupported content encoding'
        end
      else
        body.read
      end

      # Find our pluggable parser
      page = @pluggable_parser.parser(content_type).new(
        uri,
        response,
        response_body,
        response.code
      ) { |parser|
        parser.mech = self if parser.respond_to? :mech=
        if parser.respond_to?(:watch_for_set=) && @watch_for_set
          parser.watch_for_set = @watch_for_set
        end
      }

    }

    # If the server sends back keep alive options, save them
    if keep_alive_info = response['keep-alive']
      keep_alive_info.split(/,\s*/).each do |option|
        k, v = option.split(/=/)
        cache_obj[:keep_alive_options] ||= {}
        cache_obj[:keep_alive_options][k.intern] = v
      end
    end

    (response.get_fields('Set-Cookie')||[]).each do |cookie|
      Cookie::parse(uri, cookie, log) { |c|
        log.debug("saved cookie: #{c}") if log
        @cookie_jar.add(uri, c)
      }
    end

    log.info("status: #{ page.code }") if log

    res_klass = Net::HTTPResponse::CODE_TO_OBJ[page.code.to_s]

    return page if res_klass <= Net::HTTPSuccess

    if res_klass == Net::HTTPNotModified
      log.debug("Got cached page") if log
      return visited_page(uri)
    elsif res_klass <= Net::HTTPRedirection
      return page unless follow_redirect?
      log.info("follow redirect to: #{ response['Location'] }") if log
      from_uri  = page.uri
      abs_uri   = to_absolute_uri(response['Location'].to_s, page)
      page = fetch_page(abs_uri, fetch_request(abs_uri), page)
      @history.push(page, from_uri)
      return page
    end

    raise ResponseCodeError.new(page), "Unhandled response", caller
  end

  def self.build_query_string(parameters)
    vals = [] 
    parameters.each { |k,v|
      next if k.nil?
      vals <<
      [WEBrick::HTTPUtils.escape_form(k), 
       WEBrick::HTTPUtils.escape_form(v.to_s)].join("=")
    }

    vals.join("&")
  end

  def add_to_history(page)
    @history.push(page)
  end

  # :stopdoc:
  class Util
    def self.html_unescape(s)
      return s unless s
      s.gsub(/&(\w+|#[0-9]+);/) { |match|
        number = case match
        when /&(\w+);/
          Hpricot::NamedCharacters[$1]
        when /&#([0-9]+);/
          $1.to_i
        end

        number ? (number.chr rescue match) : match
      }
    end
  end
  # :startdoc:
end

end # module WWW
