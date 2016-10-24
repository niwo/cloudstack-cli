require "spec_helper"
require "cloudstack-cli"

describe VirtualMachine do

  it "should be able to run vm list" do
    out = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "list",
      CONFIG
    ]}.join ""
    out.lines.last.must_match(
      /.*(No virtual machines found.|Total number of virtual machines: \d)/
    )
  end

  it "should successfully create a vm" do
    out, err = capture_io do
      startvm = CloudstackCli::Cli.start [
        "vm",
        "create",
        "testvm1",
        "--zone=Sandbox-simulator",
        "--template=CentOS 5.3(64-bit) no GUI (Simulator)",
        "--offering=Small Instance",
        "--networks=test-network",
        "--port-rules=:80",
        "--assumeyes",
        CONFIG,
      ]
    end
    puts out
    err.must_equal ""
  end

  it "should destroy a vm" do
    out, err = capture_io do
      startvm = CloudstackCli::Cli.start [
        "vm",
        "destroy",
        "testvm1",
        "--expunge",
        "--force",
        CONFIG,
      ]
    end
    puts out
    err.must_equal ""
  end

end
