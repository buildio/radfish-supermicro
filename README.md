# Radfish::Supermicro

Supermicro adapter for the Radfish unified Redfish client library. This gem provides seamless integration between Radfish and Supermicro BMC systems.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'radfish-supermicro'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install radfish-supermicro
```

## Usage

This gem is automatically loaded by Radfish when working with Supermicro servers. When you use Radfish with a Supermicro BMC, it will automatically use this adapter:

```ruby
require 'radfish'
require 'radfish/supermicro_adapter'

# Radfish will auto-detect Supermicro BMC
client = Radfish::Client.new(
  host: '192.168.1.100',
  username: 'admin',
  password: 'password'
)

# Or explicitly specify Supermicro
client = Radfish::Client.new(
  host: '192.168.1.100',
  username: 'admin',
  password: 'password',
  vendor: 'supermicro'
)

# Use unified Radfish API
client.power_status
client.power_on
client.virtual_media_status
```

## Features

This adapter provides full Supermicro BMC support including:

- Power management (on/off/restart/cycle)
- Virtual media operations
- Boot configuration
- System information and inventory
- Storage management
- SEL (System Event Log) operations
- License management
- BIOS configuration
- Task/job monitoring

## Dependencies

- `radfish` (~> 0.1) - The main Radfish client library
- `supermicro` (~> 0.1) - Supermicro BMC client implementation

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buildio/radfish-supermicro.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).