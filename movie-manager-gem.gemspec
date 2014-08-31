# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'movie-manager-gem/version'

Gem::Specification.new do |spec|
  spec.name          = "movie-manager-gem"
  spec.version       = MovieManagerGem::VERSION
  spec.authors       = ["David Hamme"]
  spec.email         = ["dhamme@gmail.com"]
  spec.summary       = %q{A command line tool for organizing local movie files. }
  spec.description   = %q{DH Movie Manager finds local movie files, queries IMDB, and stores the data in a sqlite3 database that you can use to run commands. Search for specific actors, directors, and genres. Filter results by audience score. Update your filenames to reflect the correct title. 
Feeling indecisive? use the 'play unseen [genre]' command to play a random movie that suits your mood.}
  spec.homepage      = "https://github.com/hammeiam/movie-manager-gem"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_dependency 'imdb', '~> 0.8.2'
  spec.add_dependency 'sequel', '~> 4.13.0'
  spec.add_dependency 'thread', '~> 0.1.4'
  spec.add_dependency 'sqlite3', '~> 1.3.9'
end
