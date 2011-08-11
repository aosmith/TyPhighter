class TyPhighter
  require 'net/http'
  require 'uri'
  require 'thread'
  
  @running_threads = nil
  @finished_threads = nil
  @results = nil


  def self.test_method
    this_object = TyPhighter.new
    urls = ["http://www.google.com", "http://www.yahoo.com", "http://www.bing.com"]
    params = {}
    params[:urls] = urls
    this_object.new_threaded_http params
  end

  def initialize
    @running_threads = ThreadGroup.new
    @finished_threads = ThreadGroup.new
  end

  ##
  # Required params:
  # :urls - (POLYMORPHIC) contain a linear array or urls, or a named hash of urls
  # =>  ["http://www.google.com" , "http://www.yahoo.com", "http://www.bing.com"]
  # =>  {"http://www.google.com" : {:post_args => {"query" => "let me google that for you"}}}
  #
  # Optional params:
  # :blocking - true or false, if false
  # :port
  # :timeout - Defaults to 10 seconds
  # :headers - Defaults to empty
  # :ssl_verify - Defaults to true
  ##/
  def new_threaded_http params
    params = check_params params
    new_threads = []
    semaphore = Mutex.new
    results = []
    params[:urls].each do |url|
      new_threads << Thread.new do
        this_thread = Thread.current
        if url.start_with? "https"
          use_ssl = true
        else
          use_ssl = false
        end
        this_thread[:uri] = URI.parse(url)
        this_thread[:http] = Net::HTTP.new(this_thread[:uri].host, this_thread[:uri].port)
        this_thread[:http].use_ssl = use_ssl
        this_thread[:http].open_timeout = params[:timeout]
        this_thread[:http].read_timeout = params[:timeout]
        this_thread[:http].ssl_timeout = params[:timeout]
        this_thread[:request] = Net::HTTP::Get.new(this_thread['uri'].request_uri)
        this_thread[:response] = this_thread[:http].request(this_thread[:request])
        return_hash = {}
        return_hash[:body] = this_thread[:response].body
        semaphore.synchronize {
          results << return_hash[:body]
        }
      end
    end
    new_threads.each do |thread|
      if thread.alive?
        @running_threads.add(thread)
      else
        warn "Thread finished: " + thread.to_s
        @finished_threads.add(thread)
      end
    end
    if params[:blocking] == true
      @running_threads.list.each do |thread|
        thread.join
      end
    end
    puts results.size
  end
  
  ##
  # Returns true if all threads have completed, false otherwise
  ##
  def threads_complete
    @threads.each do |thread|
      if thread.alive?
        return true
      end
    end
    return false
  end
  
  def get_data
    
  end
  
  def block_and_wait_for_threads
    
  end

  private
  
  def check_params params
    puts params[:urls]
    if params[:urls].nil?
      raise "Must pass params[:urls]"
    end
    
    if params[:urls].kind_of? Hash
      @results = {}
    elsif params[:urls].kind_of? Array
      @results = []
    else
      raise "params[:urls] must be a hash or an array."
    end
    
    if params[:blocking].nil?
      params[:blocking] = true
      warn "Failed to pass params[:blocking], defaulting to blocking request."
    end
    
    if params[:timeout].nil?
      params[:timeout] = 10
      warn "Failed to pass params[:timeout], defaulting to 10 seconds."
    end
    
    return params
  end
  
end