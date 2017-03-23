require_relative "ssh/version"
require 'net/ssh'
require 'timeout'
require 'awesome_print'

module Oxidized
  class SSH

      attr_reader :connection, :ip, :username, :password
      attr_reader :prompt, :debug, :exec, :pty_options
      attr_reader :port, :output, :session, :connected
      
      def initialize(options)
        @ip = options[:ip]
        @username = options[:username]
        @password = options[:password]
        @verbose = options[:verbose]
        @debug = options[:debug]
        @prompt = options[:prompt]
        @exec = options[:exec]
        @pty_options = options[:pty_options] ||= { term: "vt100" }
        @port = options[:port] ||= 22
        @output = String.new
        @logger = options[:logger] ||= Logger.new(STDOUT)
        @expectation_handler = options[:expectation_handler]
        @available_ssh_options = %i(port
                                                     password
                                                     paranoid
                                                     auth_methods
                                                     number_of_password_prompts
                                                     proxy
                                                     keys
                                                     kex
                                                     encryption
                                                     verbose
                                                     )
        @ssh_options ||= options.select {|key, val| self if @available_ssh_options.include?(key) }
      end
      
      def start
        raise "MissingSSHLibrary" if !defined? Net::SSH
        @connection = Net::SSH.start(@ip, @username, @ssh_options)
        return yield self if block_given?
        return (@connection and not @connection.closed?)
      end
      
      def exec!(params, expect = @prompt)
        check_for_connection
        exec(params, expect)
        sanitize_output_buffer("\n", /\r\n/)
        sanitize_output_buffer('', params)
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
      
      #Taking place of cmd_shell
      def send_data(params, expectation)
        expect expectation
        reset_output_buffer
        send(params)
        @session.process
        expect expectation
        @output
      end
      
      def send data
        @session.send_data data
      end
      
      def expect *regexps
        regexps = [regexps].flatten
        @logger.debug "expecting #{regexps.inspect} at #{@ip}" if @debug
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
      
      #Taking place of Oxidized::Model.open_shell
      def create_session
        @session = @connection.open_channel do |channel|
          setup_channels(channel)
          #begin
            #login method should go here
           #rescue Timeout::Error
             #raise PromptUndetect, [ @output, 'not matching configured prompt', @node.prompt ].join(' ')
           #end
        end
      end
      
      def setup_channels(ch)
        set_data_hook(ch)
        request_channels(ch)
      end
      
      def set_data_hook(ch)
        ch.on_data do |_ch, data|
          @logger.debug "received #{data}" if @debug
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
        @connection and not @connection.closed?
      end
      
  end
end
