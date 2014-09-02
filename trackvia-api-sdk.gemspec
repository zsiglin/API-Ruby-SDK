# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trackvia-api-sdk/version'

Gem::Specification.new do |s|
  s.name            = 'trackvia-api-sdk'
  s.version         = Trackvia::SDK_VERSION
  s.date            = '2014-09-05'
  s.summary         = "Trackvia's API SDK"
  s.description     = "An SDK to access your Trackvia application data"
  s.authors         = [""]
  s.email           = 'info@trackvia.com'
  s.homepage        = 'https://github.com/Trackvia/API-Ruby-SDK'
  s.license         = 'Apache2'
  s.files           = `git ls-files`.split($\)
  s.executables     = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files      = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths   = ["lib"]

  s.add_dependency 'rest-client', '~> 1.7'
  s.add_dependency 'logger', '~> 1.2'
  s.add_dependency 'json', '~> 1.8'

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'minitest', '~> 5.4'
end
