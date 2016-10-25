class NetworkOffer < CloudstackCli::Base

  desc 'list', 'list network offerings'
  option :guest_ip_type, enum: %w(isolated shared),
    desc: "list network offerings by guest type."
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    offerings = client.list_network_offerings(options)
    if offerings.size < 1
      puts "No offerings found."
    else
      case options[:format].to_sym
      when :yaml
        puts({network_offers: offerings}.to_yaml)
      when :json
        puts JSON.pretty_generate(network_offers: offerings)
      else
        table = [%w(Name Display_Text Default? Guest_IP_Type State)]
        offerings.each do |offer|
          table << [
            offer['name'],
            offer['displaytext'],
            offer['isdefault'],
            offer['guestiptype'],
            offer['state'],
          ]
        end
        print_table table
      end
    end
  end

  desc "show NAME", "show detailed infos about a network offering"
  def show(name)
    unless offer = client.list_network_offerings(name: name).first
      say "Error: No network offering with name '#{name}' found.", :red
    else
      table = offer.map do |key, value|
        if key == "service"
          [ set_color("services", :yellow),  value.map{|s| s["name"]}.join(", ") ]
        else
          [ set_color("#{key}", :yellow), "#{value}" ]
        end
      end
      print_table table
    end
  end

end
