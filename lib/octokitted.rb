# frozen_string_literal: true

require "octokit"
require "logger"

require_relative "octokitted/git_plugin"

class Octokitted
  # A Octokitted class to interact with the GitHub API
  attr_reader :login, :org, :repo, :org_and_repo, :octokit, :cloned_repos

  # Initialize the class
  # :param login: The login to use for GitHubAPI interactions (defaults to the owner of the token)
  # :param org: The org to use with the Octokitted class
  # :param repo: The repo to interact with with the Octokitted class
  # :param token: The token to use to authenticate with the GitHub API
  # :param logger: The logger to use for logging
  def initialize(login: nil, org: nil, repo: nil, token: nil, logger: nil)
    @cloned_repos = []
    org_and_repo_hash = fetch_org_and_repo
    @login = login
    @org = org || org_and_repo_hash[:org]
    @repo = repo || org_and_repo_hash[:repo]
    @token = token || fetch_token
    @octokit = setup_octokit_client
    @log = logger || setup_logger
    @org_and_repo = org_and_repo_hash[:org_and_repo]
    @login = @octokit.login if @login.nil? # reset the login to the owner of the token if not provided

    # setup the git plugin
    @git = GitPlugin.new(logger: @log, login: @login, token: @token)

    @log.debug("Octokitted initialized")
    @log.debug("login: #{@octokit.login}")
    @log.debug("org: #{@org}")
    @log.debug("repo: #{@repo}")
  end

  # Setter method for the repo instance variable
  # :param repo: The repo to set
  # :return: the new org/repo
  # Example: gh.repo = "test"
  def repo=(repo)
    @repo = repo
    @org_and_repo = "#{@org}/#{@repo}"
    @log.debug("updated org/repo: #{@org_and_repo}")
  end

  # Setter method for the org instance variable
  # :param org: The org to set
  # :return: the new org/repo
  # Example: gh.org = "test"
  def org=(org)
    @org = org
    @org_and_repo = "#{@org}/#{@repo}"
    @log.debug("updated org/repo: #{@org_and_repo}")
  end

  # Clone the currently set owner/repo repository
  # :param path: The relative path to clone the repo to - (default: ".")
  # :param options: The options to pass (default: {} - https://rubydoc.info/gems/git/Git#clone-class_method)
  # :return: The Git object to operate with
  def clone(path: ".", options: {})
    result = @git.clone(org: @org, repo: @repo, path:, options:)
    @cloned_repos << result[:path]
    return result[:git_object]
  end

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
  end

  def remove_all_clones!
    @git.remove_all_clones!(@cloned_repos)
    @cloned_repos = []
  end

  private

  # construct a logger for the class
  def setup_logger
    $stdout.sync = true # don't buffer - flush immediately
    Logger.new($stdout, level: ENV.fetch("LOG_LEVEL", "INFO").upcase)
  end

  # Fetch the org and repo from the environment
  # :return: A hash containing the org and repo, and the org and repo separately
  def fetch_org_and_repo
    org_and_repo = ENV.fetch("GITHUB_REPOSITORY", nil)
    org = nil
    repo = nil

    org = org_and_repo.split("/").first unless org_and_repo.nil?
    repo = org_and_repo.split("/").last unless org_and_repo.nil?

    return { org_and_repo:, org:, repo: }
  end

  # fetch the GitHub token from the environment
  # :return: The GitHub token
  def fetch_token
    # first try to use the OCTOKIT_ACCESS_TOKEN env var if it exists
    token = ENV.fetch("OCTOKIT_ACCESS_TOKEN", nil) # if running in actions
    return token unless token.nil?

    # next try to use the GITHUB_TOKEN env var if it exists
    token = ENV.fetch("GITHUB_TOKEN", nil) # if running in actions
    return token unless token.nil?

    raise "No GitHub token found"
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
