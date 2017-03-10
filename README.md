# Oxidized::Ssh

This gem was built to extract SSH functionality away from oxidized into another gem that the community can use for purposes other than
backing up devices. For instance, searching mac tables, arp tables, etc


## Installation

gem install oxidized-ssh

```ruby
gem 'oxidized-ssh'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oxidized-ssh

## Usage
```
ssh = Oxidized::Ssh.new({ip: 'redacted', username: 'admin', password: 'redacted', verbosity: :debug, exec: false, prompt: /^(\r*[\w.@():-]+[>]\s?)$/})

ssh.start
ssh.exec!("setline 0")
output = ssh.exec!("onu show 1/1/1")
```
## Development

Todo:

  Add logging support

  Add oxidized support (Mass refactor)

    *Proxy Support

    *Paranoid support

    *Auth_method support

    *Kex support

    *Encryption support

    *Login with expect supprot

    *Mimic method names

      *Mimic method return values as well 


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/oxidized-ssh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

