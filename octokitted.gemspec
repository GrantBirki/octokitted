# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name          = "octokitted"
  spec.version       = Octokitted::Version::VERSION
  spec.authors       = ["Grant Birkinbine"]
  spec.email         = "grant.birkinbine@gmail.com"
  spec.license       = "MIT"

  spec.summary       = "A self-hydrating version of Octokit for usage in CI systems - like GitHub Actions!"
  spec.description   = <<~SPEC_DESC
    A self-hydrating version of Octokit for usage in CI systems - like GitHub Actions!
  SPEC_DESC

  spec.homepage = "https://github.com/grantbirki/octokitted"
  spec.metadata = {
    "source_code_uri" => "https://github.com/grantbirki/octokitted",
    "documentation_uri" => "https://github.com/grantbirki/octokitted",
    "bug_tracker_uri" => "https://github.com/grantbirki/octokitted/issues"
  }

  spec.add_dependency "contracts", "~> 0.17"
  spec.add_dependency "faraday-retry", "~> 2.2"
  spec.add_dependency "git", ">= 1.18", "< 3.0"
  spec.add_dependency "octokit", ">= 7.1", "< 10.0"
  spec.add_dependency "redacting-logger", "~> 1.0"

  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.files = %w[LICENSE README.md octokitted.gemspec]
  spec.files += Dir.glob("lib/**/*.rb")
  spec.require_paths = ["lib"]
end
