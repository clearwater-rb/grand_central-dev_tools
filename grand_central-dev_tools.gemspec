# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'grand_central/dev_tools/version'

Gem::Specification.new do |spec|
  spec.name          = "grand_central-dev_tools"
  spec.version       = GrandCentral::DevTools::VERSION
  spec.authors       = ["Jamie Gaskins"]
  spec.email         = ["jgaskins@gmail.com"]

  spec.summary       = %q{Client-side developer tools for GrandCentral}
  spec.homepage      = "https://github.com/clearwater-rb/grand_central-dev_tools"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
