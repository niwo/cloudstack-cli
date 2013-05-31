# Cloudstack CLI

Cloudstack CLI gives command line access to the CloudStack API commands.

## Installation

Add this line to your application's Gemfile:

    gem 'cloudstack-bootstrap'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloudstack-bootstrap

## Usage

See the help screen

    bin/cs

Example: Bootsrap a server

    bin/cs server create delete-me-10 --zone ZUERICH_IX --port-forwarding 146.159.95.194:22 146.159.95.194:80 --template CentOS-6.4-x64-v1.0 --offering demo_1cpu_1gb --networks M_ZRH_NMC-Demo

## Status

Only a fraction of the CS commands is implemented yet...


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
