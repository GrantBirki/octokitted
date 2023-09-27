# Usage

All examples below assume that the `gh` variable is an instance of `Octokitted` and has been hydrated:

```ruby
# Example

require "octokitted"

gh = Octokitted.new() # hydrated
```

## Instance Variables and Methods

### Instance Variables

| Variable | Description | Example |
| -------- | ----------- | ------- |
| `gh.login` | The GitHub handle associated to the token that was used in hydration | `GrantBirki` |
| `gh.org` | The organization associated to the repo | `GrantBirki` |
| `gh.repo` | The repo name | `octokitted` |
| `gh.org_and_repo` | The org and repo name combined | `GrantBirki/octokitted` |
| `gh.octokit` | The underlying Octokit client that can be called directly | `#<Octokit::Client:0x123456789>` |
| `gh.cloned_repos` | An array of cloned repos that have been cloned using this Gem | `["./octokitted"]` |
| `gh.log` | The logger that is used by this Gem | `#<Logger:0x123456789>` |
| `gh.github_event` | A hash of the GitHub event that triggered the workflow. This variable is only hydrated if the Gem was called in the expected fashion of a GitHub Action run | `{ action: "opened", issue: { number: 123 } }` etc |
| `gh.sha` | The SHA of the commit that triggered the workflow. This variable is only hydrated if the Gem was called in the expected fashion of a GitHub Action run | `1234567890abcdef1234567890abcdef12345678` |
| `gh.issue_number` | The issue number that triggered the workflow. This variable is only hydrated if the Gem was called in the expected fashion of a GitHub Action run | `123` |
| `gh.issue` | The underlying `Issue` object that is hydrated with the `octokitted/common/issue.rb` helper methods | `#<Octokitted::Issue:0x123456789>` |

### Instance Methods

These are methods that are available on the top level `Octokitted` instance:

#### `gh.issue_number=(issue_number)` (setter)

Sets the `issue_number` instance variable to the provided value.

Useful for switch the context of what issue you are working in

```ruby
gh.issue_number = 456
```

#### `gh.repo=(repo)` (setter)

Sets the `repo` instance variable to the provided value.

Useful for switching the context of what repo you are working in

```ruby
gh.repo = "octokitted"
```

This command will automatically update the `gh.org_and_repo` instance variable as well.

#### `gh.org=(org)` (setter)

Sets the `org` instance variable to the provided value.

Useful for switching the context of what org you are working in

```ruby
gh.org = "GrantBirki"
```

This command will automatically update the `gh.org_and_repo` instance variable as well.

#### `gh.clone(path: ".", options: {})`

Clones the repo that is associated to the `gh` instance to the provided path.

This method will return a `Git::Base` object that can be used to interact with the cloned repo.

```ruby
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
```

#### `gh.remove_clone!(path)`

Removes a repo that was previously cloned by this Gem using the provided path.

```ruby
puts gh.cloned_repos
# => ["./octokitted"]

gh.remove_clone!("./octokitted")

puts gh.cloned_repos
# => []
```

#### `gh.remove_all_clones!`

The same as `gh.remove_clone!` but will remove all repos that were previously cloned by this Gem.

```ruby
puts gh.cloned_repos
# => ["./octokitted", "./octokitted2"]

gh.remove_all_clones!

puts gh.cloned_repos
# => []
```

## Common Methods

Common methods are "helper" methods that leverage `Octokitted`'s self-hydrating nature to do common tasks that you would with `Octokit` but with less code or explict options.

### Issue

The `Issue` class is a helper class that is used to interact with GitHub issues.

Any method where `issue_number: nil` is an option will default to the `gh.issue_number` instance variable if no value is provided. If running in the proper GitHub Action context, this variable will be hydrated automatically!

#### `gh.add_labels(labels:, issue_number: nil)` (class method)

Adds the provided Array of labels to the issue.

```ruby
gh.issue.add_labels(labels: ["bug", "enhancement"])
```

#### `gh.remove_labels(labels:, issue_number: nil)` (class method)

Removes the provided Array of labels from the issue.

```ruby
gh.issue.remove_labels(labels: ["bug", "enhancement"])
```

> Note: If a label is not present on the issue, it will be ignored. This is to prevent errors from being thrown and to keep the method idempotent. It is a delight!

#### `gh.add_comment(comment, issue_number: nil)` (class method)

Adds the provided comment to the issue. Where `comment` is the comment body to add

```ruby
gh.issue.add_comment("Hello from Octokitted!")
```

#### `gh.close(issue_number: nil, options: {})` (class method)

Closes the issue that is loaded into the `gh` instance's context

```ruby
gh.issue.close
```

> By default, the issue will be "closed as completed" or the purple color for a lack of better words
