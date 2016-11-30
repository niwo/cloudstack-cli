class AffinityGroup < CloudstackCli::Base

  desc 'list', 'list affinity groups'
  option :account
  option :name
  option :type
  option :listall, type: :boolean, default: true
  option :keyword
  option :format, default: "table",
    enum: %w(table json yaml)
  def list
    resolve_account
    affinity_groups = client.list_affinity_groups(options)
    if affinity_groups.size < 1
      say "No affinity groups found."
    else
      case options[:format].to_sym
      when :yaml
        puts({affinity_groups: affinity_groups}.to_yaml)
      when :json
        puts JSON.pretty_generate(affinity_groups: affinity_groups)
      else
        table = [%w(Domain Account Name, Description, VMs)]
        affinity_groups.each do |group|
          table << [
            group['domain'], group['account'],
          	group['name'], group['description'],
            group['virtualmachineIds'] ? group['virtualmachineIds'].size : nil
          ]
        end
        print_table table
        say "Total number of affinity groups: #{affinity_groups.size}"
      end
    end
  end

end
