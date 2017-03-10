require_relative '../lib/oxidized/ssh'

ssh = Oxidized::Ssh.new({ip: 'redacted', username: 'admin', password: 'redacted', verbosity: :debug, exec: false, prompt: /^(\r*[\w.@():-]+[>]\s?)$/})
ssh.start
puts ssh.exec!("setline 0")
@output = ssh.exec!("onu show 1/1/1")
puts @output


