require "spec_helper"
require "cloudstack-cli"

describe VirtualMachine do

  it "should support all CRUD actions" do
    vmname = "testvm1"

    # CREATE
    out, err = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "create",
      vmname,
      "--zone=#{ZONE}",
      "--template=#{TEMPLATE}",
      "--offering=#{OFFERING_S}",
      "--networks=test-network",
      "--port-rules=:80",
      "--assumeyes"
    ]}
    err.must_equal ""

    # READ - LIST
    out, err = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "list"
    ]}
    err.must_equal ""
    out.must_match(
      /.*(#{vmname}).*/
    )

    # READ - SHOW
    out, err = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "show",
      vmname
    ]}
    err.must_equal ""
    out.must_match(
      /.*(#{vmname}).*/
    )

    # UPDATE - STOP
    out, err = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "stop",
      vmname,
      "--force"
    ]}
    err.must_equal ""

    # UPDATE - UPDATE ;-)
    new_vmname = "testvm11"
    out, err = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "update",
      vmname,
      "--name=#{new_vmname}",
      "--force"
    ]}
    err.must_equal ""

    # UPDATE - START
    out, err = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "start",
      new_vmname
    ]}
    err.must_equal ""

    # UPDATE - REBOOT
    out, err = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "reboot",
      new_vmname,
      "--force"
    ]}
    err.must_equal ""

    # DELETE
    out, err = capture_io{ CloudstackCli::Cli.start [
      "vm",
      "destroy",
      new_vmname,
      "--expunge",
      "--force"
    ]}
    err.must_equal ""
    
  end

end
