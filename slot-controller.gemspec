# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slot/controller/version'

Gem::Specification.new do |spec|
  spec.name          = "slot-controller"
  spec.version       = Slot::Controller::VERSION
  spec.authors       = ["Marvin Viceral"]
  spec.email         = ["marvin.viceral@gmail.com"]
  spec.summary       = %q{Code for Beaglebone for slot controller}
  spec.description   = %q{Code for Beaglebone for slot controller}
  spec.homepage      = "http://www.icenginc.com"
  spec.license       = "All Rights Reserved"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "beaglebone"
  spec.add_dependency "rack"
  spec.add_dependency "grape"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
