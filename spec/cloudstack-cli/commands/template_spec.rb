require "spec_helper"
require "cloudstack-cli"

describe Template do

  it "should list templates" do
    out, err = capture_io do
      CloudstackCli::Cli.start [
        "template",
        "list",
        "--zone=#{ZONE}"
      ]
    end
    err.must_equal ""
    out.must_include TEMPLATE
  end

end
