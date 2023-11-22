# frozen_string_literal: true

require "logger"
require "spec_helper"
require_relative "../../../lib/octokitted/git_plugin"

describe GitPlugin do
  let(:login) { "hubot" }
  let(:logger) { double("Logger").as_null_object }
  let(:token) { "faketoken" }

  context "#initialize" do
    it "ensures the class is initialized properly" do
      gp = GitPlugin.new(logger:, login:, token:)
      expect(gp.instance_variable_get(:@login)).to eq("hubot")
      expect(gp.instance_variable_get(:@token)).to eq("faketoken")
      expect(gp.instance_variable_get(:@log)).to eq(logger)
    end
  end

  context "#remove_all_clones!" do
    it "removes all cloned repos" do
      gp = GitPlugin.new(logger:, login:, token:)
      expect(FileUtils).to receive(:rm_r).with("fake-repo1").and_return(nil)
      expect(FileUtils).to receive(:rm_r).with("fake-repo2").and_return(nil)
      expect(logger).to receive(:debug).with("removing all cloned repos")
      expect(logger).to receive(:debug).with("removing cloned repo: fake-repo1")
      expect(logger).to receive(:debug).with("removing cloned repo: fake-repo2")

      gp.remove_all_clones!(%w[fake-repo1 fake-repo2])
    end
  end

  context "#remove_clone!" do
    it "removes a single cloned repo" do
      gp = GitPlugin.new(logger:, login:, token:)
      expect(FileUtils).to receive(:rm_r).with("fake-repo1").and_return(nil)
      expect(logger).to receive(:debug).with("removing cloned repo: fake-repo1")
      gp.remove_clone!("fake-repo1")
    end
  end

  context "#clone" do
    let(:git_path) { "https://#{token}@github.com/octocat/octoawesome.git" }
    let(:git) do
      double(
        "Git::Base",
        config: nil
      )
    end

    it "successfully clones a repo" do
      expect(Git).to receive(:clone)
        .with(git_path, "octoawesome", path: ".", log: logger, **{})
        .and_return(git)

      gh = GitPlugin.new(logger:, login:, token:)
      gh.clone(org: "octocat", repo: "octoawesome")
    end

    it "raises an error when trying to clone a repo" do
      expect(Git).to receive(:clone)
        .with(git_path, "octoawesome", path: ".", log: logger, **{})
        .and_raise(StandardError, "there is something wrong with your token - #{token}")

      expect(logger).to receive(:debug).with("cloning octocat/octoawesome")

      gh = GitPlugin.new(logger:, login:, token:)
      expect do
        gh.clone(org: "octocat", repo: "octoawesome")
      end.to raise_error(StandardError, "there is something wrong with your token - REDACTED_TOKEN")
    end
  end
end
