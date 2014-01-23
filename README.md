# Cloudstack CLI

[![Gem Version](https://badge.fury.io/rb/cloudstack-cli.png)](http://badge.fury.io/rb/cloudstack-cli)

cloudstack-cli is a [CloudStack](http://cloudstack.apache.org/) API command line client written in Ruby.
cloudstack-cli uses the [cloudstack_client](https://github.com/niwo/cloudstack_client) to talk to the Cloudstack API.

## Installation

Install the cloudstack-cli gem:

    $ gem install cloudstack-cli

## Setup

Create the initial configuration:

    $ cs setup

cloudstack-cli expects to find a configuartion file with the API URL and your CloudStack credentials in your home directory named .cloudstack-cli.yml. If the file is located elsewhere you can specify the loaction using the --config option.

cloudstack-cli supports multiple environments using the --environment option.

Example content of the configuration file:

    :url:         "https://my-cloudstack-server/client/api/"
    :api_key:     "cloudstack-api-key"
    :secret_key:  "cloudstack-api-secret"

    test:
      :url:         "http://my-cloudstack-testserver/client/api/"
      :api_key:     "cloudstack-api-key"
      :secret_key:  "cloudstack-api-secret"

## Usage

For additional documentation find the RubyDoc [here](http://rubydoc.info/gems/cloudstack-cli/).

See the help screen:

    $ cs

### Example: Bootsrapping a server

Bootsraps a server using a template and creating port-forwarding rules for port 22 and 80.

    $ cs server create server-01 --template CentOS-6.4-x64-v1.4 --zone DC1 --offering 1cpu_1gb --port-rules :22 :80

### Example: Run a any custom API command

Run the "listAlerts" command against the Cloudstack API with an argument of type=8:

    $ cs command listAlerts type=8

### Example: Creating a complete stack of servers

An example stackfile looks like this (my_stackfile.json)

    {
      "name": "web_stack-a",
      "description": "Web Application Stack",
      "version": "1.0",
      "zone": "DC-BIE-1",
      "group": "my_web_stack",
      "keypair": "mykeypair",
      "servers": [
        {
          "name": "web-d1, web-d2",
          "description": "Web nodes",
          "template": "CentOS-6.4-x64-v1.2",
          "offering": "1cpu_1gb",
          "networks": "server_network",
          "port_rules": ":80, :443"
        },
        {
          "name": "db-01",
          "description": "PostgreSQL Master",
          "iso": "CentOS-6.4-x86_64-swisstxt-v15",
          "disk_offering": "Perf Storage",
          "disk_size": "5",
          "offering": "2cpu_4gb",
          "networks": "server_network, storage_network"
        }
      ]
    }

Create the stack of servers from above:

    $ cs stack create my_stackfile.json

### Example: Sort computing offerings

Sort all computing offerings by CPU and Memory grouped my Domain:

    $ cs offering sort

### Example: Stop all backup routers of a given project

Stop all virtual routers of project Demo (you could filter by zone too):
(This command is helpful if you have to deploy new versions of Cloudstack when using redundant routers)

    $ cs router list --project Demo --status running --redundant-state BACKUP --command stop

Hint: You can watch the status of the command with watch.

    $ watch -n cs router list --project Demo


## References
-  [Cloudstack API documentation](http://cloudstack.apache.org/docs/api/)
-  This tool was inspired by the Knife extension for Cloudstack: [knife-cloudstack](https://github.com/CloudStack-extras/knife-cloudstack)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


## License

Released under the MIT License. See the [LICENSE](https://raw.github.com/niwo/cloudstack-cli/master/LICENSE.txt) file for further details.
