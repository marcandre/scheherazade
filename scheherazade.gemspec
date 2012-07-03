# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "scheherazade/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "scheherazade"
  s.version     = Scheherazade::VERSION
  s.authors     = ["Marc-André Lafortune"]
  s.email       = ["github@marc-andre.ca"]
  s.homepage    = "http://github.com/marcandre/scheherazade"
  s.summary     = "Entertaining fixtures for Rails"
  s.description = "With Sheherazade's imagination and storytelling skills, fixtures can be as entertaining as the “Arabian Nights”."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
end
