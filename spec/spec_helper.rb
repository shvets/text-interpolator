$: << File.expand_path('../lib', File.dirname(__FILE__))

RSpec.configure do |config|
  config.mock_with :mocha
end

