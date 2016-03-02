# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sitefull/cloud/version'

Gem::Specification.new do |spec|
  spec.name          = "sitefull-cloud"
  spec.version       = Sitefull::Cloud::VERSION
  spec.authors       = ["Stanimir Dimitrov"]
  spec.email         = ["stanchino@gmail.com"]

  spec.summary       = 'A module for automating cloud deployments using different cloud providers'
  spec.description   = <<-eos
    Configure and manage cloud deployments using different providers
  eos
  spec.homepage      = 'https://github.com/stanchino/sitefull-cloud'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.platform      = Gem::Platform::RUBY

  spec.add_dependency 'multi_json'
  spec.add_dependency 'signet'
  spec.add_dependency 'ms_rest'
  spec.add_dependency 'aws-sdk'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "shoulda-matchers"
end
