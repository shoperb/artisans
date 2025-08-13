# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'artisans/version'

Gem::Specification.new do |spec|
  spec.name          = "artisans"
  spec.version       = Artisans::VERSION
  spec.required_ruby_version = ">= 3.2.0"
  spec.authors       = ["Shoperb"]
  spec.email         = ["engineering@shoperb.com"]

  spec.summary       = 'Tool for compiling scss+liquid assets'
  spec.description   = 'Artisans compiles SCSS + Liquid assets for Shoperb themes, bundling templates and styles into deployable packages.'
  spec.homepage      = "https://www.shoperb.dev"
  spec.license       = "MIT"

  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "homepage_uri"          => "https://www.shoperb.com",
    "documentation_uri"     => "https://www.shoperb.dev",
    "source_code_uri"       => "https://github.com/shoperb/artisans",
    "bug_tracker_uri"       => "https://github.com/shoperb/artisans/issues"
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"

  spec.add_dependency "liquid", "~> 4.0"
  spec.add_dependency "sass", "~> 3"
  spec.add_dependency "haml", "~> 6"
  spec.add_dependency "rubyzip", "~> 2.3"
  spec.add_dependency "sprockets", "3.7.2"
end
