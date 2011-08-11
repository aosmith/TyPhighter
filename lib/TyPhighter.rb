require "TyPhighter/version"

module TyPhighter
  class TyPhighter
    require 'net/http'
    require 'uri'
    require 'thread'

    @running_threads = nil
    @finished_threads = nil
    @results = nil


    def self.test_method
      this_object = TyPhighter.new
      request_objects = [{:url => "http://www.google.com"},{:url => "http://www.yahoo.com"},{:url => "http://www.bing.com"}]
      params = {}
      params[:request_objects] = request_objects
      this_object.new_threaded_http params
    end

    def initialize
      @running_threads = ThreadGroup.new
      @finished_threads = ThreadGroup.new
    end

    ##
    # Required params:
    # :request_objects - contains a linear array of request objects:
    # =>  [{ :url => "http://www.google.com", :post_args => {"key" => "value"} }, {:url => "http://www.yahoo.com", :post_args => {"key" => "value"}, :options => {:timeout => 5} }]
    # =>  
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
      results = {}
      params[:request_objects].each do |request_object|
        new_threads << Thread.new do
          this_thread = Thread.current
          if request_object[:url].start_with? "https"
            use_ssl = true
          else
            use_ssl = false
          end
          this_thread[:uri] = URI.parse(request_object[:url])
          this_thread[:http] = Net::HTTP.new(this_thread[:uri].host, this_thread[:uri].port)
          this_thread[:http].use_ssl = use_ssl
          this_thread[:http].open_timeout = params[:timeout]
          this_thread[:http].read_timeout = params[:timeout]
          this_thread[:http].ssl_timeout = params[:timeout]
          if request_object[:post_args].nil?
            if request_object[:options][:headers].nil?
              this_thread[:request] = Net::HTTP::Get.new(this_thread['uri'].request_uri)
            else
              this_thread[:request] = Net::HTTP::Get.new(this_thread['uri'].request_uri, request_object[:options][:headers])
            end
          else
            if request_object[:options][:headers].nil?
              this_thread[:request] = Net::HTTP::Post.new(this_thread['uri'].request_uri)
            else
              this_thread[:request] = Net::HTTP::Post.new(this_thread['uri'].request_uri, request_object[:options][:headers])
            end
            this_thread[:request].set_form_data(request_object[:post_args])
          end
          warn "\nMaking request: " + this_thread[:request].to_s
          this_thread[:response] = this_thread[:http].request(this_thread[:request])
          return_hash = {}
          return_hash[:body] = this_thread[:response].body
          semaphore.synchronize {
            results[request_object[:url]] = return_hash[:body]
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
      results.each do |k,v|
        puts "key: " + k[0,50]
        puts "value: " + v[0,50]
      end
      nil
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
      puts params[:request_objects]
      if params[:request_objects].nil?
        raise "Must pass params[:request_objects]"
      end

      unless params[:request_objects].kind_of? Array
        raise "params[:request_objects] must be an array."
      else
        params[:request_objects].each do |request_object|
          unless request_object.kind_of? Hash
            raise "request objects must be hash: " + request_object.to_s
          end
          if request_object[:options].nil?
            request_object[:options] = {}
            warn "Failed to pass options for: " + request_object.to_s
          end
        end
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
end
