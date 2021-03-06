$:.push File.expand_path("lib", __dir__)
require "image_collector/version"

Gem::Specification.new "image_collector" do |spec|
  spec.name        = "image_collector"
  spec.version     = ImageCollector::VERSION
  spec.summary     = "Gem to download images from a given plain text file"
  spec.description = "I'll do it later"
  spec.authors     = ["Marat Zasorin"]
  spec.email       = "mzasorinwd@gmail.com"
  spec.homepage    = "https://github.com/mzsrn/image_collector"
  spec.files       = ["lib/image_collector.rb"]
  spec.license     = "MIT"
  spec.files       = Dir["{lib}/**/*", "README.md"]
  spec.require_paths = ["lib"]

  spec.bindir        = 'bin'
  spec.executables   = 'image-collector'

  spec.add_development_dependency "rake", '~> 13.0'
  spec.add_development_dependency "rspec", '~> 3.10'
  spec.add_development_dependency "webmock", '~> 3.12'
  spec.add_development_dependency "byebug", '~> 11.1'
end