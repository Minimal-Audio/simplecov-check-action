# frozen_string_literal: true

class CheckAction
  def initialize(coverage_path:, minimum_coverage:, github_token:, sha:)
    @coverage_path = coverage_path
    @minimum_coverage = minimum_coverage
    @github_token = github_token
    @sha = sha
  end

  def call
    coverage_results = CoverageResults.new(
      coverage_path: @coverage_path,
      minimum_coverage: @minimum_coverage
    )

    # Create Check Run
    request_object = Request.new(access_token: @github_token)
    request = request_object.post(uri: endpoint, body: body)

    check_run_id = JSON.parse(request.body)["id"]

    # End Check Run
    request_object.patch(uri: "#{endpoint}/#{check_run_id}", body: ending_payload(coverage_results: coverage_results))
  end

  def endpoint
    owner = "joshmfrankel"
    repo = "simplecov-check-action"

    "https://api.github.com/repos/#{owner}/#{repo}/check-runs"
  end

  def body
    {
      name: "Coverage Results",
      head_sha: @sha,
      status: "in_progress",
      started_at: Time.now.iso8601
    }
  end

  def ending_payload(coverage_results:)
    conclusion = coverage_results.passed? ? "success" : "failure"
    summary = <<~SUMMARY
      * #{coverage_results.covered_percent}% covered
      * #{coverage_results.minimum_coverage}% minimum
    SUMMARY
    {
      name: "Coverage Results",
      head_sha: @sha,
      status: "completed",
      completed_at: Time.now.iso8601,
      conclusion: conclusion,
      output: {
        title: "Coverage Results",
        summary: summary,
        text: "The text",
        annotations: []
      }
    }
  end
end
