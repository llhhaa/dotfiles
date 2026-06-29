require_relative "../../../test_helper"

class InstallBrewCasksStepTest < Minitest::Test
  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @system = FakeSystem.new
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
  end

  def test_complete_when_all_declared_casks_installed
    write_casks(["zoom", "1password"])
    @system.stub(/^brew list --cask$/, output: "zoom\n1password\n")

    step = build_step
    assert step.complete?
    assert_empty step.errors
  end

  def test_complete_false_when_cask_missing
    write_casks(["zoom", "1password"])
    @system.stub(/^brew list --cask$/, output: "zoom\n")

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("1password") })
    refute(step.errors.any? { |e| e.include?("zoom") })
  end

  def test_run_installs_only_missing_casks
    write_casks(["zoom", "1password"])
    @system.stub(/^brew list --cask$/, output: "zoom\n")

    build_step.run

    assert_includes @system.commands, "brew install --cask 1password"
    refute_includes @system.commands, "brew install --cask zoom"
  end

  def test_run_records_error_on_install_failure
    write_casks(["zoom"])
    @system.stub(/^brew list --cask$/, output: "")
    @system.stub(/^brew install --cask zoom$/, output: "boom", status: 1)

    step = build_step
    step.run

    assert(step.errors.any? { |e| e.include?("zoom") && e.include?("boom") })
  end

  def test_complete_skips_brew_when_no_casks_declared
    write_casks([])

    step = build_step
    assert step.complete?
    refute_includes @system.commands, "brew list --cask"
  end

  def test_complete_reports_missing_when_brew_list_fails
    write_casks(["zoom"])
    @system.stub(/^brew list --cask$/, output: "command not found", status: 127)

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("zoom") })
  end

  private

  def build_step
    Dotfiles::Step::InstallBrewCasksStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: "/tmp/home",
      system: @system
    )
  end

  def write_casks(casks)
    config_dir = File.join(@dotfiles_dir, "config")
    FileUtils.mkdir_p(config_dir)
    payload = {"brew" => {"casks" => casks}}
    File.write(File.join(config_dir, "config.yml"), payload.to_yaml)
  end
end
