require_relative "../../../test_helper"

class InstallSnapPackagesStepTest < Minitest::Test
  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @home = Dir.mktmpdir("home-")
    @system = FakeSystem.new
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
    FileUtils.rm_rf(@home)
  end

  def test_complete_with_no_snaps_declared
    write_snaps([])

    step = build_step
    assert step.complete?
    assert_empty step.errors
  end

  def test_complete_when_all_snaps_installed
    write_snaps(["htop"])
    @system.stub(/^snap list$/, output: "Name  Version\nhtop  3.3.0\n")

    step = build_step
    assert step.complete?
  end

  def test_incomplete_when_snap_missing
    write_snaps(["htop"])
    @system.stub(/^snap list$/, output: "Name  Version\n")

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("htop") })
  end

  def test_run_installs_missing_snaps
    write_snaps(["htop"])
    @system.stub(/^snap list$/, output: "Name  Version\n")

    build_step.run

    assert_includes @system.commands, "sudo snap install htop"
  end

  def test_run_records_error_on_install_failure
    write_snaps(["htop"])
    @system.stub(/^snap list$/, output: "Name  Version\n")
    @system.stub(/snap install htop$/, output: "boom", status: 1)

    step = build_step
    step.run

    assert(step.errors.any? { |e| e.include?("htop") && e.include?("boom") })
  end

  private

  def build_step
    Dotfiles::Step::InstallSnapPackagesStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: @home,
      system: @system
    )
  end

  def write_snaps(snaps)
    config_dir = File.join(@dotfiles_dir, "config")
    FileUtils.mkdir_p(config_dir)
    File.write(File.join(config_dir, "config.yml"), {"debian_snap_packages" => snaps}.to_yaml)
  end
end
