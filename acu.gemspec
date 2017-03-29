$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acu/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "acu"
  s.version     = Acu::VERSION
  s.authors     = ["Dariush Hasanpour"]
  s.email       = ["b.g.dariush@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Acu."
  s.description = "TODO: Description of Acu."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.2"

  s.add_development_dependency "sqlite3"
end
