# frozen_string_literal: true

require_relative "lib/radfish/supermicro/version"

Gem::Specification.new do |spec|
  spec.name = "radfish-supermicro"
  spec.version = Radfish::Supermicro::VERSION
  spec.authors = ["Jonathan Siegel"]
  spec.email = ["248302+usiegj00@users.noreply.github.com"]

  spec.summary = "Supermicro adapter for Radfish"
  spec.description = "Provides Supermicro BMC support for the Radfish unified Redfish client library"
  spec.homepage = "https://github.com/buildio/radfish-supermicro"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/buildio/radfish-supermicro"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib}/**/*", "LICENSE", "README.md", "*.gemspec"]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "radfish", "~> 0.1"
  spec.add_dependency "supermicro", "~> 0.1"
  
  spec.add_development_dependency "rspec", "~> 3.0"
end