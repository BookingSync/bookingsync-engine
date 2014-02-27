$:.push File.expand_path("../lib", __FILE__)

require "bookingsync/engine/version"

Gem::Specification.new do |s|
  s.name        = "bookingsync-engine"
  s.version     = BookingSync::ENGINE_VERSION
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of BookingSync."
  s.description = "TODO: Description of BookingSync."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.0.0"
  # s.add_dependency "omniauth-bookingsync"

  s.add_development_dependency "pg"
end
