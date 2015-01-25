require File.dirname(__FILE__) + '/wirb/version'
require File.dirname(__FILE__) + '/wirb/tokenizer'

require 'yaml'
require 'paint'

class << Wirb
  def running?() @running end

  @running = false

  # Start colorizing results, will hook into irb if IRB is defined
  def start
    require File.dirname(__FILE__) + '/wirb/irb' if defined?(IRB) && defined?(IRB::Irb) && !IRB::Irb.instance_methods.include?(:prompt_non_fancy)
    @running = true
  rescue LoadError
    warn "Couldn't activate Wirb"
  end
  alias activate start
  alias enable   start

  # Stop colorizing
  def stop
    @running = false
  end
  alias deactivate stop
  alias disable    stop

  def schema
    @schema || load_schema
  end

  def schema=(val)
    @schema = val
  end

  # Loads a color schema from a yaml file
  #   If first argument is a String: path to yaml file
  #   If first argument is a Symbol: bundled schema
  def load_schema(yaml_path = :classic)
    if yaml_path.is_a? Symbol # bundled themes
      schema_name = yaml_path.to_s
      schema_yaml = YAML.load_file(File.join(Gem.datadir('wirb'), schema_name + '.yml'))
    else
      schema_name = File.basename(yaml_path).gsub(/\.yml$/, '')
      schema_yaml = YAML.load_file(yaml_path)
    end

    if schema_yaml.is_a?(Hash)
      @schema = Hash[ schema_yaml.map{ |k,v|
        [k.to_s.to_sym, Array( v )]
      } ]
      @schema[:name] = schema_name.to_sym
    else
      raise LoadError, "Could not load the Wirb schema at: #{yaml_path}"
    end

    @schema
  end

  # Return the escape code for a given color
  def get_color(*keys)
    Paint.color(*keys)
  end

  # Colorize a string
  def colorize_string(string, *colors)
    Paint[string, *colors]
  end

  # Colorize a result string
  def colorize_result(string, custom_schema = schema)
    if @running
      check = ''
      colorful = tokenize(string).map do |kind, token|
        check << token
        colorize_string token, *Array( custom_schema[kind] )
      end.join

      # always display the correct inspect string!
      check == string ? colorful : string
    else
      string
    end
  end

end

# J-_-L

