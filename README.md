# octokitted

[![test](https://github.com/GrantBirki/octokitted/actions/workflows/test.yml/badge.svg)](https://github.com/GrantBirki/octokitted/actions/workflows/test.yml) [![lint](https://github.com/GrantBirki/octokitted/actions/workflows/lint.yml/badge.svg)](https://github.com/GrantBirki/octokitted/actions/workflows/lint.yml) [![CodeQL](https://github.com/GrantBirki/octokitted/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/GrantBirki/octokitted/actions/workflows/codeql-analysis.yml)

A self-hydrating version of Octokit for usage in CI systems - like GitHub Actions!

> **kit** or **kitted** (_verb_)
>
> Defintion: provide someone or something with the appropriate clothing or equipment.
>
> "we were all kitted out in life jackets", "our octokit client was kitted out for CI usage"

![octokitted](./docs/assets/dalle.png)

## Installation 💎

You can download this Gem from either [RubyGems](https://rubygems.org/gems/octokitted) or [GitHub Packages](https://github.com/GrantBirki/octokitted/pkgs/rubygems/octokitted)

RubyGems (Recommended):

```bash
gem install octokitted
```

> RubyGems [link](https://rubygems.org/gems/octokitted)

Via a Gemfile:

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

gem "octokit", "~> 7.1" # a dependency of octokitted
gem "octokitted", "~> X.X.X" # Replace X.X.X with the latest version
```

## Usage 💻

If you are running in the context of a **pull request** or an **issue** in GitHub Actions, you can simply create a new instance of `Octokitted` and it will automatically hydrate itself:

```ruby
# frozen_string_literal: true

require "octokitted"

# Setup a new instance of Octokitted and self-hydrate
gh = Octokitted.new()

puts "#{gh.org} #{gh.repo} #{gh.org_and_repo}"
# => GrantBirki octokitted GrantBirki/octokitted

puts gh.issue_number
# => 123

# add a comment to the issue in the context we are running in
gh.issue.add_comment(comment: "Hello from Octokitted!")

# add a label to the issue
gh.issue.add_labels(labels: ["test"])

# remove the label from the issue
gh.issue.remove_labels(labels: ["test"])

# close the issue
gh.issue.close

# swap your context to a different issue
gh.issue_number = 456
puts gh.issue_number
# => 456

```

If you want to use Octokitted outside of GitHub Actions, you can pass some of the required information to the constructor:

```ruby
# frozen_string_literal: true

require "octokitted"

# Setup a new instance of Octokitted with explicit values
gh = Octokitted.new(
    login: "GrantBirki", # The user associated with the GITHUB_TOKEN
    org: "GrantBirki", # The organization associated with the repo
    repo: "octokitted", # The repo name
    token: ENV.fetch("GITHUB_TOKEN"), # The GitHub token to use
    issue_number: 123 # The issue number to use
)

# Now you have an octokitted client that is hydrated and ready to use just as seen in the more detailed example above!

puts "#{gh.org} #{gh.repo} #{gh.org_and_repo}"
# => GrantBirki octokitted GrantBirki/octokitted

puts gh.issue_number
# => 123

# ...
```

## Release 🚀

To release a new version of this gem, simply edit the [`lib/version.rb`](lib/version.rb) in this repo. When you commit your changes to `main`, a new version will be automatically released via GitHub Actions to RubyGems and GitHub Packages.
