# frozen_string_literal: true

require_relative "lib/ridgepole/view/version"

Gem::Specification.new do |spec|
  spec.name = "ridgepole-view"
  spec.version = Ridgepole::View::VERSION
  spec.authors = ["y-sato"]
  spec.summary = "Scenic view support for Ridgepole"
  spec.description = "A Ridgepole plugin that adds database view management using the Scenic gem"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "ridgepole", ">= 1.0"
  spec.add_dependency "scenic", ">= 1.5"

  spec.add_development_dependency "rspec", "~> 3.0"
end
