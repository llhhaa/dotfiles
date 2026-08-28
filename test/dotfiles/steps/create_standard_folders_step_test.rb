require_relative "../../test_helper"

class CreateStandardFoldersStepTest < Minitest::Test
  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @home = Dir.mktmpdir("home-")
    @system = FakeSystem.new
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
    FileUtils.rm_rf(@home)
  end

  def test_complete_when_all_folders_exist
    write_folders(["~/repos", "~/personal"])
    FileUtils.mkdir_p(File.join(@home, "repos"))
    FileUtils.mkdir_p(File.join(@home, "personal"))

    step = build_step
    assert step.complete?
    assert_empty step.errors
  end

  def test_incomplete_when_folder_missing
    write_folders(["~/repos", "~/personal"])
    FileUtils.mkdir_p(File.join(@home, "repos"))

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("personal") })
    refute(step.errors.any? { |e| e.include?("repos") })
  end

  def test_run_creates_missing_folders
    write_folders(["~/repos", "~/personal"])

    build_step.run

    assert Dir.exist?(File.join(@home, "repos"))
    assert Dir.exist?(File.join(@home, "personal"))
  end

  def test_complete_with_no_folders_configured
    write_folders([])

    step = build_step
    assert step.complete?
  end

  private

  def build_step
    Dotfiles::Step::CreateStandardFoldersStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: @home,
      system: @system
    )
  end

  def write_folders(folders)
    write_config("standard_folders" => folders)
  end

  def write_config(payload)
    config_dir = File.join(@dotfiles_dir, "config")
    FileUtils.mkdir_p(config_dir)
    File.write(File.join(config_dir, "config.yml"), payload.to_yaml)
  end
end
