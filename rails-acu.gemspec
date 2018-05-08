$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acu/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rails-acu"
  s.version     = Acu::VERSION
  s.authors     = ["Dariush Hasanpour"]
  s.email       = ["b.g.dariush@gmail.com"]
  s.homepage    = "https://github.com/noise2/rails-acu"
  s.summary     = "Access Control Unit"
  s.description = "Access control unit for controller-action sets"
  s.license     = "MIT"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")

  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 5.0.0"
end
