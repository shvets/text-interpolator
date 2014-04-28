# -*- encoding: utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/lib/text_interpolator/version')

Gem::Specification.new do |spec|
  spec.name          = "text-interpolator"
  spec.summary       = %q{Simple library for interpolation of variables inside the text}
  spec.description   = %q{Simple library for interpolation of variables inside the text.}
  spec.email         = "alexander.shvets@gmail.com"
  spec.authors       = ["Alexander Shvets"]
  spec.homepage      = "http://github.com/shvets/text-interpolator"

  spec.files         = `git ls-files`.split($\)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.version       = TextInterpolator::VERSION
  spec.license       = "MIT"

  
  spec.add_development_dependency "gemspec_deps_gen", ["~> 1.1"]
  spec.add_development_dependency "gemcutter", ["~> 0.7"]

end

