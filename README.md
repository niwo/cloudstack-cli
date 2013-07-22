# Cloudstack CLI

Cloudstack CLI gives command line access to the CloudStack API commands.

## Installation

Add this line to your application's Gemfile:

    gem "cloudstack-cli"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloudstack-cli

## Setup

Create the initial configuration:

	cs setup

cloudstack-cli expects to find a configuartion file with the API URL and your CloudStack credentials in your home directory named .cloudstack-cli.yml. If the file is located elsewhere you can specify the loaction using the --config option.

Example content of the configuration file:

    :url:         "https://my-cloudstack-server/client/api/"
	:api_key:     "cloudstack-api-key"
	:secret_key:  "cloudstack-api-secret"

## Usage

See the help screen

    $ bin/cs

Example: Bootsrap a server

    $ bin/cs server create delete-me-10 --zone ZUERICH_IX --port-forwarding 146.159.95.194:22 146.159.95.194:80 --template CentOS-6.4-x64-v1.2 --offering demo_1cpu_1gb --networks M_ZRH_NMC-Demo

Example: Run a custom API command

    bin/cs command listAlerts type=8


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
