class Pod < CloudstackCli::Base

  desc 'list', 'list pods'
  def list
    pods = client.list_pods(options)
    if pods.size < 1
      say "No pods found."
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