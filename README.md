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

ssh = Oxidized::Ssh.new({ip: 'redacted', username: 'admin', password: 'redacted', verbosity: :debug, exec: false, prompt: /^(\r*[\w.@():-]+[>]\s?)$/})

ssh.start
ssh.exec!("setline 0")
output = ssh.exec!("onu show 1/1/1")

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/oxidized-ssh. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

