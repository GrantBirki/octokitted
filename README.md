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

```ruby
# frozen_string_literal: true

require "octokitted"
```

## Release 🚀

To release a new version of this gem, simply edit the [`lib/version.rb`](lib/version.rb) in this repo. When you commit your changes to `main`, a new version will be automatically released via GitHub Actions to RubyGems and GitHub Packages.
