# frozen_string_literal: true

require "git"
require "contracts"

class GitPlugin
  attr_reader :login

  include Contracts::Core
  include Contracts::Builtin

  # Initialize the class
  Contract KeywordArgs[logger: Any, login: Maybe[String], token: Maybe[String]] => Any
  def initialize(logger:, login:, token:)
    @log = logger
    @login = login
    @token = token
  end

  # Removes / cleans up all repos that this class has cloned
  # :param cloned_repos: An array of paths to cloned repos to remove
  # :return: true to indicate success
  Contract ArrayOf[String] => true
  def remove_all_clones!(cloned_repos)
    @log.debug("removing all cloned repos")
    cloned_repos.each do |path|
      @log.debug("removing cloned repo: #{path}")
      FileUtils.rm_r(path)
    end
    true
  end

  # Removes a single cloned repo
  # :param path: The path to the cloned repo to remove (String)
  # :return: true to indicate success
  Contract String => true
  def remove_clone!(path)
    @log.debug("removing cloned repo: #{path}")
    FileUtils.rm_r(path)
    return true
  end

  # Clone a repository
  # :param path: The relative path to clone the repo to - (default: ".")
  # :param options: The options to pass to the Git.clone method (default: {} - https://rubydoc.info/gems/git/Git#clone-class_method)
  # :return: Hash of the Git Object, and the path to the cloned repo
  Contract KeywordArgs[org: String, repo: String, path: Maybe[String], options: Maybe[Hash]] => Hash
  def clone(org:, repo:, path: ".", options: {})
    @log.debug("cloning #{org}/#{repo}")
    git_object = Git.clone("https://#{@token}@github.com/#{org}/#{repo}.git", repo, path:, log: @log, **options)

    # configure the git environment
    git_object.config("user.name", @login)
    git_object.config("user.email", "#{@login}@github.com")

    repo_path = File.join(path, repo)
    return { git_object:, path: repo_path }
  rescue StandardError => e
    # Remove token from error to prevent token leak
    raise e, e.message.gsub(@token, "REDACTED_TOKEN")
  end
end
