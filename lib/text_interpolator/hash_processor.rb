require 'singleton'

class HashProcessor
  include Singleton

  def process hash
    errors = {}

    content = interpolate_system_variables(hash)

    var_table = build_variables_table(content)  # one-dimensional collection of variables

    result = interpolate_variables(content, var_table, errors)

    [result, errors]
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

    var_table
  end

  def build_variable(var_table, compound_key, key, value)
    if value.kind_of? String
      var_table[key] = value
    elsif value.kind_of? Hash
      build_hash var_table, compound_key, value
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

  def interpolate_variables content, env, errors
    hash = {}

    begin
      substitutions = false

      content.each do |key, value|
        new_value = value
        substitutions = false

        if value.kind_of? String
          if value.index(/\#\{/)
            substitutions = true

            new_value = value.gsub(/\#{/, '%{')

            begin
              new_value = StringIO.new(new_value).read % env
            rescue KeyError => e
              substitutions = false

              errors << e.message
            end
          end
        elsif value.kind_of? Hash
          new_value = interpolate_variables value, env, errors
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

end