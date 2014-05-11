require 'stringio'
require 'text_interpolator/hash_processor'

class TextInterpolator

  attr_reader :errors

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
    result, @errors = *HashProcessor.instance.process(hash)

    result
  end

end
