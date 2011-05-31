require "rubygems"

gem "ramaze", "2009.03"
require "ramaze"

require "json"

Ramaze.acquire("controller/*")

require "net/ssh"
require "net/ssh/shell"

class Net::SSH::Shell
  # Method that returns the [exit_status, string_result] of a command.
  # Strips out some known terminal color patterns when skip_color=true
  def exec!(cmd, strip_color=true)
    result = ""
    res = self.execute( cmd ) do |c|
      c.on_output do |process, string|
        result << string
      end
    end
    self.wait!

    if strip_color
      # The color pattern only matches the regex when inspected
      result = result.inspect

      # Go through some known color patterns and strop them out of the result.
      [
       /\\e\[\d{1,2};\d{1,2}m/im, # Matches \e[01;34m
       /\\e\[\d{1}m/im, # Matches \e[0m
      ].each do |regex|
        result.gsub!(regex, "")
      end

      # Uninspect the result once the colors have been removed.
      # This is so things like \r\n are returned properly as \r\n etc.
      result = eval(result) # How safe is this?
    end

    return [ res.exit_status, result ]
  end
end

