# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oxidized/ssh/version'

Gem::Specification.new do |s|
  s.name         = "oxidized-ssh"
  s.version       = Oxidized::Ssh::VERSION
  s.authors      = ["Schylar"]
  s.email         = ["sutley@cwep.com"]
  s.licenses      = %w( Apache-2.0 )
  s.platform     = Gem::Platform::RUBY
  s.homepage  = 'http://github.com/MajesticFalcon/oxidized-ssh'
  s.summary    = 'Robust SSH client'
  s.description  = 'SSH client that supports shell and exec channels'
  s.rubyforge_project = s.name
  s.require_path      = 'lib'
  s.files            = ["lib/oxidized/sshwrapper.rb", "lib/oxidized/ssh/version.rb"]
  s.required_ruby_version =           '>= 2.0.0'
  s.add_runtime_dependency 'net-ssh', '~> 3.0.2'

  if defined?(RUBY_VERSION) && RUBY_VERSION > '2.3'
      s.add_runtime_dependency 'net-telnet', '~> 0'
  end

  s.add_development_dependency 'pry',      '~> 0'
  s.add_development_dependency 'bundler',  '~> 1.10'
  s.add_development_dependency 'rake',     '~> 10.0'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'mocha',    '~> 1.1'
end
