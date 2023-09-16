# frozen_string_literal: true

require "contracts"

class Issues
  include Contracts::Core
  include Contracts::Builtin

  # A helper class for common operations on GitHub Issues
  def initialize(octokitted)
    @octokit = octokitted.octokit
    @log = octokitted.log
    @octokitted = octokitted
  end

  # Adds a set of labels to an issue or pull request
  # :param labels: The labels to add to the issue (Array of strings)
  # :param issue_number: The issue number to add labels to
  Contract KeywordArgs[labels: ArrayOf[String], issue_number: Maybe[Numeric]] => Any
  def add_labels(labels:, issue_number: nil)
    # if issue_number is nil, use the issue_number set in the parent class
    issue_number = @octokitted.issue_number if issue_number.nil?

    @log.debug("adding labels: #{labels} to issue: #{issue_number}")

    @octokit.add_labels_to_an_issue(@octokitted.org_and_repo, issue_number, labels)
  end

  # Removes a set of labels from an issue or pull request
  # If the label does not exist, the exception is caught and logged
  # :param labels: The labels to remove from the issue (Array of strings)
  # :param issue_number: The issue number to remove labels from
  def remove_labels(labels:, issue_number: nil)
    # if issue_number is nil, use the issue_number set in the parent class
    issue_number = @octokitted.issue_number if issue_number.nil?

    @log.debug("removing labels: #{labels} from issue: #{issue_number}")

    labels.each do |label|
      @octokit.remove_label(@octokitted.org_and_repo, issue_number, label)
    rescue Octokit::NotFound
      @log.warn("label: #{label} not found on issue: #{issue_number}")
    end
  end
end
