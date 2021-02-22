$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "workarea/mapp_integration/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "workarea-mapp_integration"
  spec.version     = Workarea::MappIntegration::VERSION
  spec.authors     = ["Satya.Tejadvs"]
  spec.email       = ["sathyteja.dvs@trikatechnologies.com"]
  spec.homepage    = "https://github.com/trikatechnologies"
  spec.summary     = "MAPP Integration"
  spec.description = "Email subscription will be enabled through integration with Mapp Email Marketing System."
  spec.license     = "Business Software License"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = `git ls-files`.split("\n")
  spec.add_dependency 'workarea', '~> 3.x'
end
