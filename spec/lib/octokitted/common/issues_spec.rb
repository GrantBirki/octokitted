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

  context "#add_labels" do
    it "adds labels to an issue" do
      expect(octokitted).to receive(:org_and_repo).and_return(org_and_repo)
      expect(octokit).to receive(:add_labels_to_an_issue).with(org_and_repo, 1, %w[foo bar]).and_return(nil)
      issues = Issues.new(octokitted)
      issues.add_labels(labels: %w[foo bar])
    end
  end

  context "#remove_labels" do
    it "removes labels from an issue successfully" do
      expect(octokitted).to receive(:org_and_repo).and_return(org_and_repo).twice
      expect(octokit).to receive(:remove_label).with(org_and_repo, 1, "foo").and_return(nil)
      expect(octokit).to receive(:remove_label).with(org_and_repo, 1, "bar").and_return(nil)
      issues = Issues.new(octokitted)
      issues.remove_labels(labels: %w[foo bar])
    end

    it "removes labels from an issue successfully but one label did not exist on the issue" do
      expect(octokitted).to receive(:org_and_repo).and_return(org_and_repo).thrice
      expect(octokit).to receive(:remove_label).with(org_and_repo, 1, "foo").and_return(nil)
      expect(octokit).to receive(:remove_label).with(org_and_repo, 1, "bar").and_raise(Octokit::NotFound)
      expect(octokit).to receive(:remove_label).with(org_and_repo, 1, "baz").and_return(nil)
      issues = Issues.new(octokitted)
      expect(logger).to receive(:warn).with("label: bar not found on issue: 1")
      issues.remove_labels(labels: %w[foo bar baz])
    end
  end
end
