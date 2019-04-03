$:.push File.expand_path("../lib", __FILE__)

require "bookingsync/engine/version"

Gem::Specification.new do |s|
  s.name        = "bookingsync-engine"
  s.version     = BookingSync::ENGINE_VERSION
  s.authors     = ["Sebastien Grosjean", "Grzesiek Kolodziejczyk"]
  s.email       = ["dev@bookingsync.com"]
  s.homepage    = "https://github.com/BookingSync/bookingsync-engine"
  s.summary     = "A Rails engine to simplify integration with BookingSync API"
  s.description = "A Rails engine to simplify integration with BookingSync API"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", ">= 5.0.0"
  s.add_dependency "omniauth-bookingsync", '~> 0.5.0'
  s.add_dependency "bookingsync-api", ">= 0.1.7"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "dotenv-rails"
  s.add_development_dependency "pg"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "shoulda-matchers", "~> 3.0"
  s.add_development_dependency "bookingsync-stylecheck"
end
