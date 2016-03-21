class SystemVm < CloudstackCli::Base

  desc 'list', 'list system VMs'
  option :zone, desc: "the name of the availability zone"
  option :state, desc: "state of the system VM"
  option :type, desc: "the system VM type.",
    enum: %w(consoleproxy secondarystoragevm)
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_zone
    vms = client.list_system_vms(options)
    if vms.size < 1
      say "No system VM's found."
    else
      case options[:format].to_sym
      when :yaml
        puts({system_vms: vms}.to_yaml)
      when :json
        puts JSON.pretty_generate(system_vms: vms)
      else
        table = [%w(Name Zone State Type)]
        vms.each do |vm|
          table << [
            vm['name'], vm['zonename'], vm['state'], vm['systemvmtype']
          ]
        end
        print_table table
        say "Total number of system VM's: #{vms.size}"
      end
    end
  end

  desc 'show NAME', 'show system VM'
  def show(name)
    unless vm = client.list_system_vms(name: name).first
      say "No system vm with name #{name} found."
    else
      table = vm.map do |key, value|
        [ set_color("#{key}:", :yellow), "#{value}" ]
      end
      print_table table
    end
  end

  desc "start NAME", "start a system VM"
  def start(name)
    unless vm = client.list_system_vms(name: name).first
      say "No system vm with name #{name} found."
    else
      say("Starting system VM #{name}", :magenta)
      client.start_system_vm(id: vm['id'])
      say " OK.", :green
    end
  end

  desc "stop NAME", "stop a system VM"
  def stop(name)
    unless vm = client.list_system_vms(name: name).first
      say "No system vm with name #{name} found."
    else
      exit unless options[:force] || yes?("Stop system VM #{name}? [y/N]:", :magenta)
      client.stop_system_vm(id: vm['id'])
      say " OK.", :green
    end
  end

  desc "reboot NAME", "reboot a system VM"
  def reboot(name)
    unless vm = client.list_system_vms(name: name).first
      say "No system vm with name #{name} found."
    else
      exit unless options[:force] || yes?("Reboot system VM #{name}? [y/N]:", :magenta)
      client.reboot_system_vm(id: vm['id'])
      say " OK.", :green
    end
  end

end
