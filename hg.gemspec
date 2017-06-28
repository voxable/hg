lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hg/version'

# rubocop:disable Metrics/BlockLength

Gem::Specification.new do |spec|
  spec.name          = 'hg'
  spec.version       = Hg::VERSION
  spec.authors       = ['Matt Buck']
  spec.email         = ['matt@voxable.io']

  spec.summary       = 'A conversational interface framework for Ruby on Rails.'
  spec.homepage      = 'https://rubygems.org/hg'
  # TODO: Add description
  # spec.description   =
  spec.license       = 'MIT'

  spec.files         = Dir[
    '{app,bin,config,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md'
  ]
  spec.test_files    = Dir['spec/**/*']

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'facebook-messenger', '~> 0.13.0'
  spec.add_runtime_dependency 'fuzzy_match', '~> 2.1.0'
  spec.add_runtime_dependency 'rails', '>= 5.0.0'

  # Background Jobs
  spec.add_runtime_dependency 'sidekiq', '~> 5.0.0'
  # API.ai NLU
  spec.add_runtime_dependency 'api-ai-ruby', '~> 1.2.3'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec-rails', '~> 3.5.2'
  spec.add_development_dependency 'sqlite3', '~> 1.3.11'
  spec.add_development_dependency 'rubocop', '~> 0.49.1'
  spec.add_development_dependency 'simplecov', '~> 0.13.0'
  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0.8'
  # TODO: Drop these from tests
  spec.add_development_dependency 'hashie', '~> 3.5.4'
end

# rubocop:enable Metrics/BlockLength
