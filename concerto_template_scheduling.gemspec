$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "concerto_template_scheduling/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "concerto_template_scheduling"
  s.version     = ConcertoTemplateScheduling::VERSION
  s.authors     = ["Marvin Frederickson"]
  s.email       = ["marvin.frederickson@gmail.com"]
  s.homepage    = "https://github.com/concerto-addons/concerto_template_scheduling"
  s.summary     = "Scheduling of Templates for Screens"
  s.description = "Schedule templates for screens in Concerto Digital Signage."

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_runtime_dependency "rails", "~> 4.2.6"
  s.add_runtime_dependency "ice_cube", "~> 0.16.2"
  s.add_runtime_dependency "recurring_select", '~> 1.2.1'

  #s.add_development_dependency "sqlite3"
end
