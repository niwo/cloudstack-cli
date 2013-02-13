module SshCommand
  require 'net/ssh'

  def SshCommand.run(connection, *commands)
    ENV['HOME'] = File.dirname(__FILE__) # fixes "non-absolute home" exceptions
    output = ""
    Net::SSH.start(connection[:host], connection[:username], :password => connection[:password]) do |session|
      commands.each do |cmd| 
        output = session.exec!("source ~/.bash_profile && " + cmd)
        yield output if block_given?
      end
    end
    output
  end
end
