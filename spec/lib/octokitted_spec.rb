# frozen_string_literal: true

require "logger"
require "spec_helper"
require_relative "../../lib/octokitted"
require_relative "../../lib/octokitted/git_plugin"

describe Octokitted do
  before(:each) do
    allow(ENV).to receive(:fetch).with("OCTOKIT_PER_PAGE", 100).and_return(100)
    allow(ENV).to receive(:fetch).with("OCTOKIT_AUTO_PAGINATE", true).and_return(true)
    allow(ENV).to receive(:fetch).with("OCTOKIT_ACCESS_TOKEN", nil).and_return(nil)
    allow(ENV).to receive(:fetch).with("GITHUB_REPOSITORY", nil).and_return("github/octocat")
    allow(ENV).to receive(:fetch).with("GITHUB_TOKEN", nil).and_return("faketoken")
  end

  let(:login) { "hubot" }
  let(:logger) { double("Logger").as_null_object }
  let(:token) { "faketoken" }

  context "#initialize" do
    it "ensures the class is initialized properly" do
      expect(logger).to receive(:debug).with("Octokitted initialized")
      gh = Octokitted.new(logger:, login:)
      expect(gh.instance_variable_get(:@login)).to eq("hubot")
      expect(gh.instance_variable_get(:@org)).to eq("github")
      expect(gh.instance_variable_get(:@repo)).to eq("octocat")
      expect(gh.instance_variable_get(:@token)).to eq(token)
      expect(gh.instance_variable_get(:@log)).to eq(logger)
      expect(gh.instance_variable_get(:@org_and_repo)).to eq("github/octocat")
      expect(gh.octokit).to be_a(Octokit::Client)
    end

    it "sets up the class and builds a logger as well" do
      allow(ENV).to receive(:fetch).with("LOG_LEVEL", "INFO").and_return("DEBUG")
      expect(Logger).to receive(:new).with($stdout, level: "DEBUG").and_return(logger)
      expect(logger).to receive(:debug).with("Octokitted initialized")
      expect(logger).to receive(:debug).with("login: hubot")
      Octokitted.new(logger: nil, login:)
    end

    it "logs a warning if no github token is found" do
      expect(ENV).to receive(:fetch).with("OCTOKIT_ACCESS_TOKEN", nil).and_return(nil)
      expect(ENV).to receive(:fetch).with("GITHUB_REPOSITORY", nil).and_return("github/octocat")
      expect(ENV).to receive(:fetch).with("GITHUB_TOKEN", nil).and_return(nil)
      expect(logger).to receive(:warn).with("No GitHub token found")
      Octokitted.new(logger:, login:)
    end
  end

  context "#repo=" do
    it "sets the repo instance variable" do
      gh = Octokitted.new(logger:, login:)
      expect(gh.instance_variable_get(:@repo)).to eq("octocat")
      gh.repo = "test"
      expect(gh.instance_variable_get(:@repo)).to eq("test")
      expect(gh.instance_variable_get(:@org_and_repo)).to eq("github/test")
    end

    it "sets the org instance variable" do
      gh = Octokitted.new(logger:, login:)
      expect(gh.instance_variable_get(:@org)).to eq("github")
      gh.org = "test"
      expect(gh.instance_variable_get(:@org)).to eq("test")
      expect(gh.instance_variable_get(:@org_and_repo)).to eq("test/octocat")
    end
  end

  context "#clone" do
    let(:git_base) { Git::Base.new }

    let(:git) do
      double(
        "GitPlugin",
        clone: {
          git_object: git_base,
          path: "fake-repo"
        },
        remove_all_clones!: nil,
        remove_clone!: nil
      )
    end

    let(:git_leading_dot) do
      double(
        "GitPlugin",
        clone: {
          git_object: git_base,
          path: "./fake-repo"
        },
        remove_all_clones!: nil,
        remove_clone!: nil
      )
    end

    it "successfully clones a repo" do
      expect(GitPlugin).to receive(:new).with(logger:, login:, token:).and_return(git)
      gh = Octokitted.new(logger:, login:)
      expect(gh.cloned_repos).to eq([])
      gh.clone
      expect(gh.cloned_repos).to eq(["fake-repo"])
    end

    it "successfully clones a repo and then deletes it" do
      expect(GitPlugin).to receive(:new).with(logger:, login:, token:).and_return(git)
      gh = Octokitted.new(logger:, login:)
      expect(gh.cloned_repos).to eq([])
      gh.clone
      expect(gh.cloned_repos).to eq(["fake-repo"])
      gh.remove_clone!("fake-repo")
      expect(gh.cloned_repos).to eq([])
    end

    it "successfully clones a repo and then deletes it with using a leading './'" do
      expect(GitPlugin).to receive(:new).with(logger:, login:, token:).and_return(git_leading_dot)
      gh = Octokitted.new(logger:, login:)
      expect(gh.cloned_repos).to eq([])
      gh.clone
      expect(gh.cloned_repos).to eq(["./fake-repo"])
      gh.remove_clone!("./fake-repo")
      expect(gh.cloned_repos).to eq([])
    end

    it "successfully clones a repo and then deletes it with using a leading './' when not provided" do
      expect(GitPlugin).to receive(:new).with(logger:, login:, token:).and_return(git_leading_dot)
      gh = Octokitted.new(logger:, login:)
      expect(gh.cloned_repos).to eq([])
      gh.clone
      expect(gh.cloned_repos).to eq(["./fake-repo"])
      gh.remove_clone!("fake-repo")
      expect(gh.cloned_repos).to eq([])
    end

    it "successfully clones three repos and then deletes all clones" do
      fake_git = double("GitPlugin")
      expect(GitPlugin).to receive(:new).with(logger:, login:, token:).and_return(fake_git)
      expect(fake_git).to receive(:clone)
        .and_return(
          { git_object: git_base, path: "fake-repo1" },
          { git_object: git_base, path: "fake-repo2" },
          { git_object: git_base, path: "fake-repo3" }
        )
      gh = Octokitted.new(logger:, login:)
      gh.clone
      expect(gh.cloned_repos).to eq(["fake-repo1"])
      gh.clone
      expect(gh.cloned_repos).to eq(%w[fake-repo1 fake-repo2])
      gh.clone
      expect(gh.cloned_repos).to eq(%w[fake-repo1 fake-repo2 fake-repo3])

      expect(fake_git).to receive(:remove_clone!).and_return(nil)
      gh.remove_clone!("fake-repo2")
      expect(gh.cloned_repos).to eq(%w[fake-repo1 fake-repo3])

      expect(fake_git).to receive(:remove_all_clones!).and_return(nil)
      gh.remove_all_clones!
      expect(gh.cloned_repos).to eq([])
    end

    it "fails to delete a repo that wasn't cloned" do
      expect(GitPlugin).to receive(:new).with(logger:, login:, token:).and_return(git)
      gh = Octokitted.new(logger:, login:)
      expect(gh.cloned_repos).to eq([])
      gh.clone
      expect(gh.cloned_repos).to eq(["fake-repo"])

      expect { gh.remove_clone!("bad-repo") }.to raise_error(
        StandardError, "Not a cloned repository - path: bad-repo"
      )
    end
  end
end
