class Stack < CloudstackCli::Base

	desc "create STACKFILE", "create a stack of servers"
  def create(stack_file)
  	#begin
      stack = JSON.parse(File.read(stack_file))
    #rescue Exception => e
      $stderr.puts "Can't find the stack file #{stack_file}."
      exit
    #end
    	p stack
  end

end