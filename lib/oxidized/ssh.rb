require_relative "ssh/version"
require 'net/ssh'
require 'timeout'
require 'awesome_print'

module Oxidized
  class SSH

      attr_reader :connection, :ip, :username, :password
      attr_reader :prompt, :verbosity, :exec, :pty_options
      attr_reader :port, :output, :session
      
      def initialize(options)
        @ip = options[:ip]
        @username = options[:username]
        @password = options[:password]
        @verbosity = options[:verbosity]
        @prompt = options[:prompt]
        @exec = options[:exec]
        @pty_options = options[:pty_options] ||= { term: "vt100" }
        @port = options[:port] ||= 22
        @output = String.new
        @logger = options[:logger] ||= Logger.new(STDOUT)
        @expectation_handler = options[:expectation_handler]
      end
      
      def start
        raise "MissingSSHLibrary" if !defined? Net::SSH
        @connection = Net::SSH.start(@ip, @username, password: @password, verbose: @verbosity, port: @port)
        return yield self if block_given?
        return (@connection and not @connection.closed?)
      end
      
      def exec!(params)
        check_for_connection
        exec(params)
        @output.gsub(/\r\n/,"\n")
      end
      
      def check_for_connection
        prep_connection unless @session
      end
      
      def exec(params)
        @logger.debug "sending command #{params} with expectation of #{@prompt}"
        if @exec
          @connection.exec!(params)
        else
          collect_output(params)
        end
      end
      
      def collect_output(params)
        send_data((params + "\n"))
        return @output
      end
      
      def send_data(params)
        expect @prompt
        reset_output_buffer
        send(params)
        @session.process
        expect @prompt
        @output
      end
      
      def send(params)
        @session.send_data params
      end
      
      def expect *regexps
        regexps = [regexps].flatten
        @logger.debug "expecting #{regexps.inspect} at #{@ip}"
        @connection.loop(0.1) do
          sleep 0.1
          match = regexps.find { |regexp| @output.match regexp }
          return match if match
          true
        end
      end
      
      def prep_connection
        return true if @exec
        start_channel_requests
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
          @logger.debug "received #{data}"
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
      
      def disconnect
        Timeout::timeout(5) { @connection.loop }
        rescue Errno::ECONNRESET, Net::SSH::Disconnect, IOError
        ensure
        (@connection.close rescue true) unless @connection.closed?
      end
      
  end
end
