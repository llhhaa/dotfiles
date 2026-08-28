require_relative "../../../test_helper"

class InstallNonAptPackagesStepTest < Minitest::Test
  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @home = Dir.mktmpdir("home-")
    @system = FakeSystem.new
    @system.stub(/^dpkg --print-architecture$/, output: "amd64")
    @system.stub(%r{/etc/os-release}, output: "24.04")
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
    FileUtils.rm_rf(@home)
  end

  def test_complete_when_command_exists
    write_ghostty

    step = build_step
    assert step.complete?
    assert_empty step.errors
  end

  def test_incomplete_when_command_missing
    write_ghostty
    @system.stub(/command -v ghostty/, status: 127)

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("ghostty") })
  end

  def test_run_downloads_matching_asset_and_installs_it
    write_ghostty
    @system.stub(/command -v ghostty/, status: 127)
    @system.stub(%r{api\.github\.com/repos/mkasberg/ghostty-ubuntu/releases/latest}, output: release_json)
    @system.stub(/curl -fsSL -o /, status: 0)

    build_step.run

    assert_includes @system.commands, "curl -fsSL -o #{Dir.tmpdir}/ghostty.deb https://example.com/ghostty_1.3.1-0.ppa2_amd64_24.04.deb"
    assert_includes @system.commands, "sudo apt-get install -y #{Dir.tmpdir}/ghostty.deb"
  end

  def test_run_uses_custom_command_when_configured
    write_package("name" => "mytool", "repo" => "example/mytool", "asset_glob" => "*_{arch}.deb", "command" => "myctl")
    @system.stub(/command -v myctl/, status: 127)
    @system.stub(%r{api\.github\.com/repos/example/mytool/releases/latest}, output: release_json("mytool_1.0_amd64.deb"))
    @system.stub(/curl -fsSL -o .*mytool\.deb/, status: 0)

    step = build_step
    refute step.complete?

    step.run
    assert_includes @system.commands, "sudo apt-get install -y #{Dir.tmpdir}/mytool.deb"
  end

  def test_run_errors_when_no_asset_matches
    write_ghostty
    @system.stub(/command -v ghostty/, status: 127)
    @system.stub(%r{api\.github\.com/repos/mkasberg/ghostty-ubuntu/releases/latest}, output: release_json("ghostty_1.3.1-0.ppa2_arm64_24.04.deb"))

    step = build_step
    step.run

    assert(step.errors.any? { |e| e.include?("amd64_24.04.deb") })
    refute(@system.commands.any? { |c| c.include?("apt-get install") })
  end

  def test_run_errors_when_api_returns_garbage
    write_ghostty
    @system.stub(/command -v ghostty/, status: 127)
    @system.stub(%r{api\.github\.com}, output: "<html>rate limited</html>")

    step = build_step
    step.run

    assert(step.errors.any? { |e| e.include?("ghostty") })
  end

  def test_run_records_error_when_install_fails
    write_ghostty
    @system.stub(/command -v ghostty/, status: 127)
    @system.stub(%r{api\.github\.com/repos/mkasberg/ghostty-ubuntu/releases/latest}, output: release_json)
    @system.stub(/curl -fsSL -o /, status: 0)
    @system.stub(/apt-get install -y .*ghostty\.deb$/, output: "boom", status: 100)

    step = build_step
    step.run

    assert(step.errors.any? { |e| e.include?("ghostty") && e.include?("boom") })
  end

  private

  def build_step
    Dotfiles::Step::InstallNonAptPackagesStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: @home,
      system: @system
    )
  end

  def write_ghostty
    write_package(
      "name" => "ghostty",
      "repo" => "mkasberg/ghostty-ubuntu",
      "asset_glob" => "*_{arch}_{os_version}.deb"
    )
  end

  def write_package(package)
    config_dir = File.join(@dotfiles_dir, "config")
    FileUtils.mkdir_p(config_dir)
    File.write(File.join(config_dir, "config.yml"), {"debian_non_apt_packages" => [package]}.to_yaml)
  end

  def release_json(*asset_names)
    assets = (asset_names.empty? ? ["ghostty_1.3.1-0.ppa2_amd64_24.04.deb"] : asset_names).map do |name|
      {"name" => name, "browser_download_url" => "https://example.com/#{name}"}
    end
    JSON.generate({"tag_name" => "v1.3.1", "assets" => assets})
  end
end
