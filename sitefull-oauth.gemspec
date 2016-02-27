# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sitefull/oauth/version'

Gem::Specification.new do |spec|
  spec.name          = "sitefull-oauth"
  spec.version       = Sitefull::Oauth::VERSION
  spec.authors       = ["Stanimir Dimitrov"]
  spec.email         = ["stanchino@gmail.com"]

  spec.summary       = 'Cloud provider OAuth for Ruby applications'
  spec.description   = <<-eos
    Allow for authentication against different cloud provider APIs using OAuth authorization code grant flow
  eos
  spec.homepage      = 'https://github.com/stanchino/sitefull-oauth'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.platform      = Gem::Platform::RUBY

  spec.add_dependency 'multi_json', '~> 1.11'
  spec.add_dependency 'signet', '~> 0.7'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "spec"
  spec.add_development_dependency "shoulda-matchers"
end
