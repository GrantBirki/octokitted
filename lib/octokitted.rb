# frozen_string_literal: true

require "octokit"
require "logger"
require "contracts"

require_relative "octokitted/git_plugin"
require_relative "octokitted/common/issue"

class Octokitted
  # A Octokitted class to interact with the GitHub API
  attr_reader :login,
              :org,
              :repo,
              :org_and_repo,
              :octokit,
              :cloned_repos,
              :log,
              :github_event,
              :sha,
              :issue_number,
              :issue

  include Contracts::Core
  include Contracts::Builtin

  # Initialize the class
  # :param event_path: The path to the GitHub event data (defaults to the GITHUB_EVENT_PATH env var)
  # :param login: The login to use for GitHubAPI interactions (defaults to the owner of the token)
  # :param org: The org to use with the Octokitted class
  # :param repo: The repo to interact with with the Octokitted class
  # :param issue_number: The issue/pull_request number to interact with with the Octokitted class
  # :param token: The token to use to authenticate with the GitHub API
  # :param logger: The logger to use for logging
  #
  # Note: If you do not provide an org, repo, token, or issue_number, Octokitted will attempt to self-hydrate...
  # ... these values from the environment and the GitHub event data when you call `.new` on the class
  def initialize(event_path: nil, login: nil, org: nil, repo: nil, issue_number: nil, token: nil, logger: nil)
    @log = logger || setup_logger
    @cloned_repos = []
    @event_path = event_path || ENV.fetch("GITHUB_EVENT_PATH", nil)
    @sha = ENV.fetch("GITHUB_SHA", nil)
    org_and_repo_hash = fetch_org_and_repo(org, repo)
    @login = login
    @org = org || org_and_repo_hash[:org]
    @repo = repo || org_and_repo_hash[:repo]
    @token = token || fetch_token
    @octokit = setup_octokit_client
    @org_and_repo = org_and_repo_hash[:org_and_repo]
    @github_event = fetch_github_event(@event_path)
    @issue_number = issue_number || fetch_issue_number(@github_event)
    @login = @octokit.login if @login.nil? # reset the login to the owner of the token if not provided

    # setup the git plugin
    @git = GitPlugin.new(logger: @log, login: @login, token: @token)
    # setup the common Issue plugin
    @issue = Issue.new(self)

    @log.debug("Octokitted initialized")
    @log.debug("login: #{@octokit.login}")
    @log.debug("org: #{@org}")
    @log.debug("repo: #{@repo}")
  end

  # Setter method for the repo instance variable
  # :param repo: The repo to set
  # :return: it does not return as it is a setter method
  # Example: gh.repo = "test"
  Contract String => Any
  def repo=(repo)
    @repo = repo
    @org_and_repo = "#{@org}/#{@repo}"
    @log.debug("updated org/repo: #{@org_and_repo}")
  end

  # Setter method for the org instance variable
  # :param org: The org to set
  # :return: it does not return as it is a setter method
  # Example: gh.org = "test"
  Contract String => Any
  def org=(org)
    @org = org
    @org_and_repo = "#{@org}/#{@repo}"
    @log.debug("updated org/repo: #{@org_and_repo}")
  end

  # Clone the currently set owner/repo repository
  # :param path: The relative path to clone the repo to - (default: ".")
  # :param options: The options to pass (default: {} - https://rubydoc.info/gems/git/Git#clone-class_method)
  # :return: The Git object to operate with
  Contract Maybe[String], Maybe[Hash] => Git::Base
  def clone(path: ".", options: {})
    result = @git.clone(org: @org, repo: @repo, path:, options:)
    @cloned_repos << result[:path]
    return result[:git_object]
  end

  # Remove a cloned repository
  # :param path: The relative path to the cloned repo to remove (String)
  # :return: true to indicate success
  Contract String => true
  def remove_clone!(path)
    valid = false

    # check if the repo exists in the cloned_repos array
    valid = true if @cloned_repos.include?(path)

    # check if the repo exists in the cloned_repos array with a leading './'
    if @cloned_repos.include?("./#{path}")
      valid = true
      path = "./#{path}" # update the path to include the relative path so the .delete method works
    end

    raise StandardError, "Not a cloned repository - path: #{path}" unless valid

    @git.remove_clone!(path)
    @cloned_repos.delete(path)
    true
  end

  # Remove all cloned repositories that have been cloned with this instance of Octokitted
  # :return: true to indicate success
  Contract None => true
  def remove_all_clones!
    @git.remove_all_clones!(@cloned_repos)
    @cloned_repos = []
    true
  end

  private

  # construct a logger for the class
  def setup_logger
    $stdout.sync = true # don't buffer - flush immediately
    Logger.new($stdout, level: ENV.fetch("LOG_LEVEL", "INFO").upcase)
  end

  # Fetch the org and repo from the environment
  # :return: A hash containing the org and repo, and the org and repo separately
  Contract Maybe[String], Maybe[String] => Hash
  def fetch_org_and_repo(org, repo)
    # if org and repo are provided, and not nil, use them
    return { org_and_repo: "#{org}/#{repo}", org:, repo: } if org && repo

    org_and_repo = ENV.fetch("GITHUB_REPOSITORY", nil)
    org = nil
    repo = nil

    org = org_and_repo.split("/").first unless org_and_repo.nil?
    repo = org_and_repo.split("/").last unless org_and_repo.nil?

    return { org_and_repo:, org:, repo: }
  end

  # A helper method that attempts to self-hydrate context from the GitHub event data
  # In Actions, the GITHUB_EVENT_PATH env var is set to a file containing the GitHub json event data
  # If it exists, we try to load it into this class
  # :param event_path: The path to the GitHub event data (defaults to the GITHUB_EVENT_PATH env var)
  # :return: A Hash of the GitHub event data or nil if not found
  Contract Maybe[String] => Maybe[Hash]
  def fetch_github_event(event_path)
    if ENV.fetch("GITHUB_ACTIONS", nil).nil?
      @log.debug("Not running in GitHub Actions - GitHub Event data not auto-hydrated")
      return nil
    end
    unless event_path
      @log.warn("GITHUB_EVENT_PATH env var not found")
      return nil
    end

    @log.info("GitHub Event data auto-hydrated")
    return JSON.parse(File.read(event_path), symbolize_names: true)
  end

  # A helper method that attempts to self-hydrate the issue_number from the GitHub event data
  # :param github_event: The GitHub event data (Hash)
  # :return: The issue_number or nil if not found
  Contract Maybe[Hash] => Maybe[Numeric]
  def fetch_issue_number(github_event)
    if github_event.nil?
      @log.debug("GitHub event data not found - issue_number not auto-hydrated")
      return nil
    end

    issue_number = (github_event[:issue] || github_event[:pull_request] || github_event)[:number]

    @log.info("issue_number auto-hydrated - issue_number: #{issue_number}")
    return issue_number
  end

  # fetch the GitHub token from the environment
  # :return: The GitHub token or nil if not found
  Contract None => Maybe[String]
  def fetch_token
    # first try to use the OCTOKIT_ACCESS_TOKEN env var if it exists
    token = ENV.fetch("OCTOKIT_ACCESS_TOKEN", nil) # if running in actions
    return token unless token.nil?

    # next try to use the GITHUB_TOKEN env var if it exists
    token = ENV.fetch("GITHUB_TOKEN", nil) # if running in actions
    return token unless token.nil?

    # if we get here, we don't have a token - this is okay because we can still do some things...
    # ... without a token, rate limiting can be an issue
    @log.warn("No GitHub token found")
    return nil
  end

  # Setup an Octokit client
  # :return: An Octokit client
  def setup_octokit_client
    Octokit::Client.new(
      access_token: @token,
      login: @login,
      page_size: ENV.fetch("OCTOKIT_PER_PAGE", 100)&.to_i,
      auto_paginate: ENV.fetch("OCTOKIT_AUTO_PAGINATE", true)
    )
  end
end
