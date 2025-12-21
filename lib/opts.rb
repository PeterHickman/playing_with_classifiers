class Opts
  attr_reader :arguments

  def initialize(commands)
    @options = {}
    @arguments = []

    parse(commands)
  end

  def option(name, type, default = nil)
    if @options.key?(name)
      case type
      when 'integer'
        @options[name].to_i
      when 'float'
        @options[name].to_f
      when 'boolean'
        @options[name] == 'true'
      when 'string'
        @options[name]
      else
        raise "Unknown option type [#{type}]"
      end
    elsif default.nil?
      raise "Missing option [#{name}]"
    else
      default
    end
  end

  private

  def parse(commands)
    end_of_options = false

    while commands.any?
      x = commands.shift

      if end_of_options
        @arguments << x
      elsif x == '--'
        end_of_options = true
      elsif x.start_with?('--')
        y = commands.shift
        @options[x] = y
      else
        @arguments << x
        end_of_options = true
      end
    end
  end
end
