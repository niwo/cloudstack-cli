class Pod < CloudstackCli::Base

  desc 'list', 'list pods'
  option :zone
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_zone
    pods = client.list_pods(options)
    if pods.size < 1
      say "No pods found."
    else
      case options[:format].to_sym
      when :yaml
        puts({pods: pods}.to_yaml)
      when :json
        puts JSON.pretty_generate(pods: pods)
      else
        table = [["Name", "Start-IP", "End-IP", "Zone"]]
        pods.each do |pod|
          table << [
          	pod['name'], pod['startip'],
            pod['endip'], pod['zonename']
          ]
        end
        print_table table
        say "Total number of pods: #{pods.count}"
      end
    end
  end

end
