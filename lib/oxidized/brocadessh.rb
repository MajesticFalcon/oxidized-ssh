  # ______________________________________________________________________________________
# **Title**: Vendor/Channel Agnostic SSH Wrapper
#
# **Author**: Schylar Utley
#
# **Description**: Allows for channel and exec ssh
#
# **Usage:**: SSH.new
#_______________________________________________________________________________________

  
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
  end
  
  def start
    raise "MissingSSHLibrary" if !defined? Net::SSH
    @connection = Net::SSH.start(@ip, @username, password: @password, verbose: @verbosity, port: port)
    return yield self if block_given?
    return (@connection and not @connection.closed?)
  end
  
  def exec!(params)
    prep_connection
    exec(params)
  end
  
  def exec(params)
    if @exec
      @connection.exec!(params)
    else
      collect_output(params)
    end
  end
  
  def collect_output(params)
    send_data("setline 0\n")
    send_data(params + "\n")
    return @output
  end
  
  def send_data(params)
    expect @prompt
    reset_output_buffer
    @session.send_data params
    @session.process
    expect @prompt
  end
  
  def expect *regexps
    #Return to ssh channels if we detect that the prompt has returned.
    regexps = [regexps].flatten
    @connection.loop(0.1) do
      #give the commands a chance to execute
      sleep 0.1
      #check for prompt
      match = regexps.find { |regexp| @output.match regexp }
      #return to execution if commands are done
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
      @output << data
    end
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
  
end
  