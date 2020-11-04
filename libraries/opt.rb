
class OptHandler
  def initialize
    @raw = ARGV.dup
    while ARGV.length > 0
      ARGV.delete(ARGV[0])
    end
    @variables = {}
    @flags = []
    @commands = []
    for item in @raw
      if item.start_with? "--" and item.include? ":"
        key = item.split(":")[0].gsub("--", "")
        val = item.split(":")[1]
        @variables[key] = val
      elsif item.start_with? "--" and item.include? "="
        key = item.split("=")[0].gsub("--", "")
        val = item.split("=")[1]
        @variables[key] = val
      elsif item.start_with? "-"
        @flags.append item.gsub "-", ""
      else
        @commands.append item
      end
    
    end
  end
  attr_accessor :commands
  attr_accessor :variables
  attr_accessor :flags
  attr_reader :raw
  def to_s
    "#{@raw}\n#{@variables}\n#{@flags}\n#{@commands}"
  end
  def hasFlag?(val)
      return @flags.include? val
  end

  def get(key, default = nil)
    if @variables.key? key
      return @variables[key]
    else
      return default
    end
  end
  
  def command(ind = 0, default = "")
    if ind >= @commands.length
      return default
    else
      return @commands[ind]
    end
  end
end
