require_relative "../test_helper"

class OutputFormatterTest < Minitest::Test
  def setup
    @system_calls = []
    @exit_codes = []
  end

  def test_renders_notice_title_and_message
    results = base_results.merge(notices: [
      {title: "Backed up existing file", message: "/home/x → /home/x.bak"}
    ])

    build_formatter(results).display

    call = find_call("Backed up existing file")
    refute_nil call
    assert(call.any? { |a| a.is_a?(String) && a.include?("/home/x → /home/x.bak") })
  end

  def test_renders_warning_title_and_message
    results = base_results.merge(warnings: [
      {title: "Some Warning", message: "warning detail"}
    ])

    build_formatter(results).display

    call = find_call("Some Warning")
    refute_nil call
    assert(call.any? { |a| a.is_a?(String) && a.include?("warning detail") })
  end

  def test_renders_errors_grouped_under_step_name
    results = base_results.merge(
      failed_steps: ["Some Step"],
      errors: [
        {step: "Some Step", message: "boom"},
        {step: "Some Step", message: "kaboom"}
      ]
    )

    build_formatter(results).display

    call = find_call("Some Step")
    refute_nil call
    assert(call.any? { |a| a.is_a?(String) && a.include?("- boom") })
    assert(call.any? { |a| a.is_a?(String) && a.include?("- kaboom") })
  end

  def test_exits_with_failure_when_failed_steps_present
    results = base_results.merge(failed_steps: ["Bad Step"])

    build_formatter(results).display

    assert_includes @exit_codes, 1
  end

  def test_displays_success_banner_when_no_failures
    build_formatter(base_results).display

    refute_nil find_call("All Steps Complete!")
    assert_empty @exit_codes
  end

  private

  def base_results
    {
      failed_steps: [],
      table_data: [["Some Step", "✓", "No"]],
      warnings: [],
      notices: [],
      errors: []
    }
  end

  def build_formatter(results)
    recording_formatter(results, system_calls: @system_calls, exit_codes: @exit_codes)
  end

  def find_call(snippet)
    @system_calls.find { |args| args.any? { |a| a.is_a?(String) && a.include?(snippet) } }
  end
end
