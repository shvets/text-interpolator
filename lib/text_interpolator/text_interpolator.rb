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
    string = interpolate_env_vars string
    string = string.gsub(/\#{/, '%{') if string.index(/\#\{/)

    StringIO.new(string).read % env
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
    hash.each do |key, value|
      new_value = interpolate_env_vars value

      hash[key] = new_value if new_value
    end

    env = hash.reduce({}) do |result, value|
      result[value[0]] = value[1]

      result
    end

    begin
      substitutions = false

      hash.each do |key, value|
        if value.index(/\#\{/)
          substitutions = true

          value = value.gsub(/\#{/, '%{')

          hash[key] = StringIO.new(value).read % env
        end
      end
    end while substitutions

    hash
  end

  private

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
