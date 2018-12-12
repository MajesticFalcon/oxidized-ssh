require_relative "ssh/version"
require 'net/ssh'
require 'timeout'

module Oxidized
  class SSHWrapper

      attr_reader :connection, :ip, :username, :password
      attr_reader :prompt, :debug, :exec
      attr_reader :port, :output, :session

      attr_writer :login, :username_prompt, :password_prompt
      attr_writer :pty_options
      
      def initialize(options)
        @ip = options[:ip]
        @username = options[:username]
        @password = options[:password]
        @verbose = options[:verbose]
        @debug = options[:debug]
        @prompt = options[:prompt]
        @exec = options[:exec] || false
        @pty_options = options[:pty_options] ||= { term: "vt100" }
        @port = options[:port] ||= 22
        @output = String.new
        @logger = options[:logger] ||= Logger.new(STDOUT)
        @auth_methods = options[:auth_methods] ||= ["publickey", "hostbased", "password"]
        @expectation_handler = options[:expectation_handler]
	@proxy = prep_proxy(options[:proxy])
	@paranoid = options[:paranoid] ||= false
      end
      
      def prep_proxy(proxy)
        if proxy_host = proxy
          proxy_command = "ssh "
          proxy_command += "-o StrictHostKeyChecking=no " unless secure
          proxy_command += "#{proxy_host} -W %h:%p"
          return Net::SSH::Proxy::Command.new(proxy_command)
        end
      end

      def start
        raise "MissingSSHLibrary" if !defined? Net::SSH
        @connection = Net::SSH.start(@ip, @username, password: @password, verbose: @verbose, port: @port, auth_methods: @auth_methods, proxy: @proxy, paranoid: @paranoid)
	check_for_connection
        return yield self if block_given?
        return (@connection and not @connection.closed?)
      end
      
      def exec!(params, expect = @prompt)
        check_for_connection
        exec(params, expect)
        sanitize_output_buffer("\n", /\r\n/)
        sanitize_output_buffer('', params)
        @logger.debug params if @debug
        @output
      end
      
      def check_for_connection
        prep_connection unless @session
      end
      
      def exec(params, expectation)
        if @exec
          @logger.debug "sending exec command #{params}" if @debug
          @output  = @connection.exec!(params)
        else
          @logger.debug "sending command #{params} with expectation of #{expectation}" if @debug
          collect_output(params, expectation)
        end
      end
      
      def collect_output(params, expectation)
        send_data((params + "\n"), expectation)
        return @output
      end
      
      def send_data(params, expectation)
	reset_output_buffer
        send(params)
        @session.process
        expect expectation if expectation
        @output
      end
      
      def send(params)
        @session.send_data params =~ /\n/ ? params : "#{params}\n" 
      end
      
      def expect *regexps
        regexps = [regexps].flatten
        @logger.debug "expecting #{regexps.inspect} at #{@ip}" if @debug
        @connection.loop(0.1) do
	  @logger.debug @output if @debug
          sleep 0.1
          match = regexps.find { |regexp| @output.match regexp }
          return match if match
          true
        end
      end
      
      def prep_connection
        return true if @exec
        start_channel_requests
	login
      end
      
      def login
	if @login
          match = expect @username_prompt, @prompt
	  if match == @login_prompt
  	    exec @username, @password_prompt
	    exec @password
          end
        else
	  expect @prompt
	end
	
      end

      def start_channel_requests
        create_session
      end
      
      def create_session
        @session = @connection.open_channel do |channel|
          setup_channels(channel)
	end
      end
      
      def setup_channels(ch)
	set_data_hook(ch)
        request_channels(ch)
      end
      
      def set_data_hook(ch)
        ch.on_data do |_ch, data|
          #@logger.debug "received #{data}" if @debug
          @output << data
          @output = expectation_list_handler(@output) if @expectation_handler
        end
      end
      
      def expectation_list_handler(data)
        @expectation_handler.each_slice(2) do |handler, meth|
          handler.method(meth.to_sym).call(self, data)
        end
        @output
      end
      
      def request_channels(ch)
        ch.request_pty @pty_options do |_ch, success_pty|
          raise NoShell, "Can't get PTY" unless success_pty
          ch.send_channel_request 'shell' do |_ch, success_shell|
            raise NoShell, "Can't get shell" unless success_shell
          end
        end
      end
      
      def reset_output_buffer
        @output = ''
      end
      
      def sanitize_output_buffer sub, *regexs
        @logger.debug "sanitizing #{regexs.join("|")} with #{sub}" if @debug
        @output.gsub!(/#{regexs.join("|")}/, sub)
      end
      
      def disconnect
        Timeout::timeout(5) { @connection.loop }
        rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
        ensure
        (@connection.close rescue true) unless @connection.closed?
      end
	
      def connected?
        @connection.closed?
      end
      
  end
end
