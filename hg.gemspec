# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hg/version'

Gem::Specification.new do |spec|
  spec.name          = 'hg'
  spec.version       = Hg::VERSION
  spec.authors       = ['Matt Buck']
  spec.email         = ['matt@voxable.io']

  spec.summary       = %q{A library for building Facebook Messenger bots.}
  spec.homepage      = "https://rubygems.org/hg"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.test_files = Dir['spec/**/*']

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'facebook-messenger', '~> 0.11.0'
  spec.add_runtime_dependency 'fuzzy_match', '~> 2.1.0'
  spec.add_runtime_dependency 'rails', '~> 5.0.1'
  # Service objects
  spec.add_runtime_dependency 'interactor-rails', '~> 2.0.2'
  # Enhanced Hashes
  spec.add_runtime_dependency 'hashie', '~> 3.5.4'
  # Background Jobs
  spec.add_runtime_dependency 'sidekiq', '~> 4.2.9'
  # API.ai NLU
  spec.add_runtime_dependency 'api-ai-ruby', '~> 1.2.3'

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec-rails', '~> 3.5.2'
  spec.add_development_dependency 'sqlite3', '~> 1.3.11'

end
