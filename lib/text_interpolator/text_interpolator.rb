require 'stringio'

class TextInterpolator

  def errors
    @errors ||= []
  end

  def clear_errors
    errors.clear
  end

  def interpolate object, env={}
    if object.kind_of? String
      interpolate_string object, env
    elsif object.kind_of? Hash
      interpolate_hash object
    elsif object.kind_of? IO
      interpolate_io object, env
    else
      object
    end
  end

  def interpolate_string string, env={}
    clear_errors

    env = symbolize_keys env

    value = interpolate_system_variable string

    var_table = build_variables_table(env)  # one-dimensional collection of variables

    begin
      new_value = interpolate_variable value, var_table
    rescue KeyError => e
      new_value = string
      errors << e.message
    end

    new_value
  end

  def interpolate_hash hash
    clear_errors

    content = interpolate_system_variables(hash)

    var_table = build_variables_table(content)  # one-dimensional collection of variables

    interpolate_variables(content, var_table)
  end

  def interpolate_io io, env={}
    result = ''

    io.each do |line|
      result += interpolate_string(line, env)
      result += '\n' unless io.eof?
    end

    result
  end

  private

  def interpolate_system_variables hash
    content = {}

    hash.each do |key, value|
      if value.kind_of? String
        new_value = interpolate_system_variable value

        content[key] = new_value if new_value
      elsif value.kind_of? Hash
        content[key] = interpolate_system_variables value
      else
        content[key] = value
      end
    end

    content
  end

  def interpolate_system_variable value
    new_value = value

    while new_value.index('ENV[')
      index1 = new_value.index("ENV[")
      index2 = new_value.index("]")

      name = new_value[index1+5..index2-2]

      left = (index1 == 0) ? '' : new_value[0..index1-1]
      right = new_value[index2+1..-1]

      new_value = left + ENV[name] + right
    end

    new_value
  end

  def build_variables_table content
    var_table = {}

    content.each do |key, value|
      build_variable(var_table, key, key, value)
    end

    var_table.each do |key, value|
      var_table[key] = interpolate_variable value.to_s, var_table
    end

    var_table
  end

  def build_variable(var_table, compound_key, key, value)
    if value.kind_of? Hash
      build_hash var_table, compound_key, value
    else
      var_table[key] = value
    end
  end

  def build_hash var_table, compound_key, hash
    hash.each do |key, value|
      new_compound_key = "#{compound_key}.#{key}"

      if value.kind_of? Hash
        build_variable(var_table, new_compound_key, key, value)
      else
        var_table[new_compound_key.to_sym] = value
      end
    end
  end

  def interpolate_variables content, env
    hash = {}

    begin
      substitutions = false

      content.each do |key, value|
        new_value = value
        substitutions = false

        if value.kind_of? String
          if value.index(/\#\{/)
            substitutions = true

            begin
              new_value = interpolate_variable value, env
            rescue KeyError => e
              substitutions = false

              errors << e.message
            end
          end
        elsif value.kind_of? Hash
          new_value = interpolate_variables value, env
        end

        if hash[key] == new_value
          substitutions = false
        else
          hash[key] = new_value
        end
      end
    end while substitutions

    hash
  end

  def interpolate_variable value, env
    new_value = value.index(/\#\{/) ? value.gsub(/\#{/, '%{') : value

    StringIO.new(new_value).read % env
  end

  def symbolize_keys hash
    new_hash = {}

    hash.each do |key, value|
      new_value = if value.kind_of? String
        value
      elsif value.kind_of? Hash
        symbolize_keys value
      else
        value
      end

      new_hash[key.to_sym] = new_value
    end

    new_hash
  end

end
