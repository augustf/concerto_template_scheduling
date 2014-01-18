$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "concerto_template_scheduling/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "concerto_template_scheduling"
  s.version     = ConcertoTemplateScheduling::VERSION
  s.authors     = ["Marvin Frederickson"]
  s.email       = ["marvin.frederickson@gmail.com"]
  s.homepage    = ""
  s.summary     = "Scheduling of Templates for Screens"
  s.description = "Schedule templates for screens in Concerto."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.16"

  s.add_development_dependency "sqlite3"
end
