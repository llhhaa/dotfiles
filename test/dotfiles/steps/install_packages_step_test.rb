require_relative "../../test_helper"

class InstallPackagesStepTest < Minitest::Test
  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @home = Dir.mktmpdir("home-")
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
    FileUtils.rm_rf(@home)
  end

  def test_complete_when_all_commands_exist
    @system = linux_system
    write_packages("gh" => {"brew" => "gh", "debian" => "gh"})

    step = build_step
    assert step.complete?
    assert_empty step.errors
  end

  def test_incomplete_when_managed_command_missing
    @system = linux_system
    write_packages("gh" => {"brew" => "gh", "debian" => "gh"})
    @system.stub(/command -v gh/, status: 127)

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("gh") })
  end

  def test_packages_without_debian_name_are_unmanaged_on_linux
    @system = linux_system
    write_packages("gh" => {"brew" => "gh", "debian" => nil})
    @system.stub(/command -v gh/, status: 127)

    step = build_step
    assert step.complete?
  end

  def test_packages_without_brew_name_are_unmanaged_on_macos
    @system = macos_system
    write_packages(
      "gh" => {"brew" => "gh", "debian" => "gh"},
      "wl-copy" => {"brew" => nil, "debian" => "wl-clipboard"}
    )
    @system.stub(/command -v wl-copy/, status: 127)

    step = build_step
    assert step.complete?
  end

  def test_command_key_overrides_package_name_for_existence_check
    @system = linux_system
    write_packages("ripgrep" => {"brew" => "ripgrep", "debian" => "ripgrep", "command" => "rg"})
    @system.stub(/command -v rg/, status: 127)

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("rg") })
  end

  def test_run_installs_missing_packages_via_apt_on_linux
    @system = linux_system
    write_packages(
      "gh" => {"brew" => "gh", "debian" => "gh"},
      "fzf" => {"brew" => "fzf", "debian" => "fzf"}
    )
    @system.stub(/command -v gh/, status: 127)

    build_step.run

    assert_includes @system.commands, "sudo apt-get update"
    assert_includes @system.commands, "sudo apt-get install -y gh"
    refute_includes @system.commands, "sudo apt-get install -y fzf"
  end

  def test_run_installs_missing_packages_via_brew_on_macos
    @system = macos_system
    write_packages("gh" => {"brew" => "gh", "debian" => "gh"})
    @system.stub(/command -v gh/, status: 127)

    build_step.run

    assert_includes @system.commands, "brew install gh"
    refute(@system.commands.any? { |c| c.include?("apt-get") })
  end

  def test_run_skips_index_refresh_when_nothing_missing
    @system = linux_system
    write_packages("gh" => {"brew" => "gh", "debian" => "gh"})

    build_step.run

    refute(@system.commands.any? { |c| c.include?("apt-get update") })
  end

  def test_run_records_error_on_install_failure
    @system = linux_system
    write_packages("gh" => {"brew" => "gh", "debian" => "gh"})
    @system.stub(/command -v gh/, status: 127)
    @system.stub(/apt-get install -y gh$/, output: "boom", status: 100)

    step = build_step
    step.run

    assert(step.errors.any? { |e| e.include?("gh") && e.include?("boom") })
  end

  def test_depends_on_apt_sources_step
    assert_includes Dotfiles::Step::InstallPackagesStep.depends_on, Dotfiles::Step::InstallAptSourcesStep
  end

  private

  def linux_system
    LinuxFakeSystem.new
  end

  def macos_system
    MacOSFakeSystem.new
  end

  def build_step
    Dotfiles::Step::InstallPackagesStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: @home,
      system: @system
    )
  end

  def write_packages(packages)
    config_dir = File.join(@dotfiles_dir, "config")
    FileUtils.mkdir_p(config_dir)
    File.write(File.join(config_dir, "config.yml"), {"packages" => packages}.to_yaml)
  end

  class LinuxFakeSystem < FakeSystem
    def macos?
      false
    end

    def debian?
      true
    end
  end

  class MacOSFakeSystem < FakeSystem
    def macos?
      true
    end

    def debian?
      false
    end
  end
end
