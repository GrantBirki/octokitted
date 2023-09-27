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

This section goes over general usage of this Gem

### Configuration

The following table goes into detail about the configuration options that can be passed into the `Octokitted.new()` constructor:

> It should be noted that when calling `Octokitted.new()` in the proper GitHub Action's context, no configuration is required to be passed into `.new()` because this Gem will fully self-hydrate itself. The `Required` field is only in the table below for reference if you are not running this Gem in GitHub Actions.

| Option | Environment Variable | Description | Required |
| ------ | -------------------- | ----------- | -------- |
| `login` | - | The GitHub handle associated with the provided `token`. Defaults to the owner of the token | no |
| `org` | `GITHUB_REPOSITORY` | The GitHub organization or user that owns a given repository. This value self-hydrates from the `GITHUB_REPOSITORY` env var when run in GitHub Actions | no, can be set after construction |
| `repo` | `GITHUB_REPOSITORY` | The GitHub repository name. This value self-hydrates from the `GITHUB_REPOSITORY` env var when run in GitHub Actions | no, can be set after construction |
| `issue_number` | `GITHUB_EVENT_PATH` | The GitHub issue number. This value self-hydrates from the `GITHUB_EVENT_PATH` env var when run in GitHub Actions. The event json object is read from disk on the Action's runner which contains issue number information | no, can be set after construction |
| `token` | `GITHUB_TOKEN` or `OCTOKIT_ACCESS_TOKEN` | The GitHub token to use for authentication. This value self-hydrates from the `GITHUB_TOKEN` env var when run in GitHub Actions | yes, required for construction |
| `logger` | - | The logger to use for logging. You can pass in your own logger or use the one this Gem auto-creates by default | no |

It should be noted that you can configure the log level that is used through the `LOG_LEVEL` environment variable. The default log level is `INFO`.

### GitHub Actions

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

### Outside of GitHub Actions

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

### Native Git Usage

If you system / container has the `git` binary installed, you can also use this Gem to run native Git commands:

```ruby
# frozen_string_literal: true

require "octokitted"

# Setup a new instance of Octokitted with explicit values
gh = Octokitted.new(
    login: "GrantBirki", # The user associated with the GITHUB_TOKEN
    org: "GrantBirki", # The organization associated with the repo
    repo: "octokitted", # The repo name
    token: ENV.fetch("GITHUB_TOKEN") # The GitHub token to use
)

# Check to see if there are any cloned repos
puts gh.cloned_repos
# => []

# Clone the repo we setup our client with and get back a Git::Base object
git = gh.clone

# Check again to see that we have one locally cloned repo at the path displayed
puts gh.cloned_repos
# => ["./octokitted"]

git.checkout("new_branch", new_branch: true, start_point: "main")

git.add # git add -- "."
# git.add(:all=>true) # git add --all -- "."
# git.add("file_path") # git add -- "file_path"
# git.add(["file_path_1", "file_path_2"])

git.commit("message")
# git.commit_all("message")

git.push
# git.push(git.remote("name"))

# remove the repo we just cloned
gh.remove_all_clones!

puts gh.cloned_repos
# => []
```

> Read more about the native Git Ruby Gem [here](https://github.com/ruby-git/ruby-git)

## Release 🚀

To release a new version of this gem, simply edit the [`lib/version.rb`](lib/version.rb) in this repo. When you commit your changes to `main`, a new version will be automatically released via GitHub Actions to RubyGems and GitHub Packages.
