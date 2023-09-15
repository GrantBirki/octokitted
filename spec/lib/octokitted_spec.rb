# frozen_string_literal: true

require "logger"
require "spec_helper"
require_relative "../../lib/octokitted"

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

  context "#initialize" do
    it "ensures the class is initialized properly" do
      expect(logger).to receive(:debug).with("Octokitted initialized")
      gh = Octokitted.new(logger:, login:)
      expect(gh.instance_variable_get(:@login)).to eq("hubot")
      expect(gh.instance_variable_get(:@org)).to eq("github")
      expect(gh.instance_variable_get(:@repo)).to eq("octocat")
      expect(gh.instance_variable_get(:@token)).to eq("faketoken")
      expect(gh.instance_variable_get(:@log)).to eq(logger)
      expect(gh.instance_variable_get(:@org_and_repo)).to eq("github/octocat")
      expect(gh.client).to be_a(Octokit::Client)
    end

    it "sets up the class and builds a logger as well" do
      allow(ENV).to receive(:fetch).with("LOG_LEVEL", "INFO").and_return("DEBUG")
      expect(Logger).to receive(:new).with($stdout, level: "DEBUG").and_return(logger)
      expect(logger).to receive(:debug).with("Octokitted initialized")
      expect(logger).to receive(:debug).with("login: hubot")
      Octokitted.new(logger: nil, login:)
    end

    it "fails if no GitHub token is found" do
      expect(ENV).to receive(:fetch).with("OCTOKIT_ACCESS_TOKEN", nil).and_return(nil)
      expect(ENV).to receive(:fetch).with("GITHUB_REPOSITORY", nil).and_return("github/octocat")
      expect(ENV).to receive(:fetch).with("GITHUB_TOKEN", nil).and_return(nil)
      expect(logger).not_to receive(:debug).with("Octokitted initialized")
      expect { Octokitted.new(logger:, login:) }.to raise_error("No GitHub token found")
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
end
