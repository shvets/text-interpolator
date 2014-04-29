class TextInterpolator

  def interpolate object, env={}
    if object.kind_of? String
      interpolate_string object, env
    elsif object.kind_of? IO
      interpolate_io object, env
    elsif object.kind_of? Hash
      interpolate_hash object
    else
      object
    end
  end

  def interpolate_string string, env={}
    new_string = replace_special_symbols(string)

    StringIO.new(new_string).read % env
  end

  def interpolate_io io, env={}
    result = ''

    io.each do |line|
      result += interpolate_string(line, env)
      result += '\n' unless io.eof?
    end

    result
  end

  def interpolate_hash hash
    env = hash.reduce({}) do |result, value|
      result[value[0]] = value[1]

      result
    end

    hash.each do |key, value|
      new_value = replace_special_symbols(value)

      hash[key] = StringIO.new(new_value).read % env
    end

    hash
  end

  private

  def replace_special_symbols string
    new_string = string

    new_string = new_string.gsub(/\#{/, '%{') if new_string.index(/\#\{/)
    new_string = interpolate_env_vars(new_string) if new_string.index('ENV[')

    new_string
  end

  def interpolate_env_vars value
    while value.index('ENV[')
      value = interpolate_env_var value
    end

    value
  end

  def interpolate_env_var value
    index1 = value.index("ENV[")
    index2 = value.index("]")

    name = value[index1+5..index2-2]

    left = (index1 == 0) ? '' : value[0..index1-1]
    right = value[index2+1..-1]

    left + ENV[name] + right
  end

end
