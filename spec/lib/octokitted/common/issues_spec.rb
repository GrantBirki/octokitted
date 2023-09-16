# frozen_string_literal: true

require "logger"
require "spec_helper"
require_relative "../../../../lib/octokitted/common/issues"

describe Issues do
  let(:logger) { double("Logger").as_null_object }
  let(:octokit) { double("Octokit") }
  let(:octokitted) { double("Octokitted", log: logger, octokit:, issue_number: 1) }
  let(:org_and_repo) { "octocat/octoawesome" }

  context "#initialize" do
    it "ensures the class is initialized properly" do
      issues = Issues.new(octokitted)
      expect(issues.instance_variable_get(:@log)).to eq(logger)
    end
  end

  context "#label" do
    it "adds labels to an issue" do
      expect(octokitted).to receive(:org_and_repo).and_return(org_and_repo)
      expect(octokit).to receive(:add_labels_to_an_issue).with(org_and_repo, 1, %w[foo bar]).and_return(nil)
      issues = Issues.new(octokitted)
      issues.label(labels: %w[foo bar])
    end
  end
end
