
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ezcater_slack/version"

Gem::Specification.new do |spec|
  spec.name          = "ezcater_slack"
  spec.version       = EzcaterSlack::VERSION
  spec.authors       = ["ezCater, Inc"]
  spec.email         = ["engineering@ezcater.com"]

  spec.summary       = 'Ezcater Slack message DSL and client.'
  spec.description   = 'Ezcater Slack message DSL and client.'

  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "https://ezcater.jfrog.io"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  # end

  spec.files = Dir['lib/**/*'] + Dir['spec/**/*']

  spec.required_ruby_version = ">= 2.7.0"
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'slack-ruby-client', '~> 2.2'
  spec.add_dependency 'rails'
  spec.add_dependency 'httparty'

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"
end
