# frozen_string_literal: true

require "contracts"

class Issue
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
    issue_number = construct_issue_numer(issue_number)
    @log.debug("adding labels: #{labels} to issue: #{issue_number}")

    @octokit.add_labels_to_an_issue(@octokitted.org_and_repo, issue_number, labels)
  end

  # Removes a set of labels from an issue or pull request
  # If the label does not exist, the exception is caught and logged
  # :param labels: The labels to remove from the issue (Array of strings)
  # :param issue_number: The issue number to remove labels from
  Contract KeywordArgs[labels: ArrayOf[String], issue_number: Maybe[Numeric]] => Any
  def remove_labels(labels:, issue_number: nil)
    issue_number = construct_issue_numer(issue_number)
    @log.debug("removing labels: #{labels} from issue: #{issue_number}")

    labels.each do |label|
      @octokit.remove_label(@octokitted.org_and_repo, issue_number, label)
    rescue Octokit::NotFound
      @log.warn("label: #{label} not found on issue: #{issue_number}")
    end
  end

  # Adds a comment to an issue or pull request
  # :param comment: The comment to add to the issue (String)
  # :param issue_number: The issue number to add the comment to
  Contract KeywordArgs[comment: String, issue_number: Maybe[Numeric]] => Any
  def add_comment(comment:, issue_number: nil)
    issue_number = construct_issue_numer(issue_number)
    @log.debug("adding comment: #{comment} to issue: #{issue_number}")

    @octokit.add_comment(@octokitted.org_and_repo, issue_number, comment)
  end

  # Closes an issue
  # :param issue_number: The issue number to close
  Contract KeywordArgs[issue_number: Maybe[Numeric], options: Maybe[Hash]] => Any
  def close(issue_number: nil, options: {})
    issue_number = construct_issue_numer(issue_number)
    @log.debug("closing issue: #{issue_number}")

    @octokit.close_issue(@octokitted.org_and_repo, issue_number, options)
  end

  private

  # Helper method to construct the issue number from the auto-hydrated issue_number if it exists
  # :param issue_number: The issue number to use if not nil
  # :return: The issue number to use
  # Note: If the issue_number is nil, we trye use the auto-hydrated issue_number...
  # ... if the issue_number is not nil, we use that
  Contract Maybe[Numeric] => Numeric
  def construct_issue_numer(issue_number)
    return @octokitted.issue_number if issue_number.nil?

    return issue_number
  end
end
