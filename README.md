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
For exec channels
ssh = Oxidized::SSH.new({ip: 'redacted', username: 'admin', password: 'redacted', exec: true)
ssh.start
ssh.exec!("ifconfig")

For shell channels
host = Oxidized::SSH.new({ip: 'redacted', prompt: Regexp.new(/^Vty-[0-9]\#$/), username: 'admin', password: password)
host.start
host.exec!("ifconfig")

For shell channels that need custom expectation handles                                                                                                                           #[class to call method on, method to call]
host = Oxidized::SSH.new({ip: 'redacted', prompt: Regexp.new(/^Vty-[0-9]\#$/), username: 'admin', password: password, expectation_handler: [b, :expects]})
host.start
host.exec!("show running-config")

```
## Development

Todo:


  Add oxidized support (Mass refactor)

    *Proxy Support

    *Paranoid support

    *Auth_method support

    *Kex support

    *Encryption support

    *Mimic method names

      *Mimic method return values as well 


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/oxidized-ssh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

