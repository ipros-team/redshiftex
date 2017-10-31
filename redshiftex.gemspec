# -*- encoding: utf-8 -*-

require File.expand_path('../lib/redshiftex/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "redshiftex"
  gem.version       = Redshiftex::VERSION
  gem.summary       = %q{redshift utility}
  gem.description   = %q{redshift utility}
  gem.license       = "MIT"
  gem.authors       = ["Hiroshi Toyama"]
  gem.email         = "toyama0919@gmail.com"
  gem.homepage      = "https://github.com/ipros-team/redshiftex"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'thor', '~> 0.19.1'
  gem.add_dependency 'activerecord'
  gem.add_dependency 'ridgepole'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'pry', '~> 0.10.1'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 2.4'
  gem.add_development_dependency 'rubocop', '~> 0.24.1'
  gem.add_development_dependency 'rubygems-tasks', '~> 0.2'
  gem.add_development_dependency 'yard', '~> 0.8'
end
