require "rubygems"

gem "ramaze", "2009.03"
require "ramaze"

require "json"

Ramaze.acquire("controller/*")

require "net/ssh"
require "net/ssh/shell"

class Net::SSH::Shell
  # Method that returns the [exit_status, string_result] of a command.
  def exec!(cmd)
    # For now, just make sure that there are no colors in the ls output
    cmd.gsub!(/^ls ?/, "ls --color=none ")
    result = ""
    res = self.execute( cmd ) do |c|
      c.on_output do |process, string|
        result << string
      end
    end
    self.wait!
    return [ res.exit_status, result ]
  end
end

