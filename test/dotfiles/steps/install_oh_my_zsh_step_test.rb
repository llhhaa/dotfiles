require_relative "../../test_helper"

class InstallOhMyZshStepTest < Minitest::Test
  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @home = Dir.mktmpdir("home-")
    @system = FakeSystem.new
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
    FileUtils.rm_rf(@home)
  end

  def test_complete_when_installed
    FileUtils.mkdir_p(File.join(@home, ".oh-my-zsh"))

    step = build_step
    assert step.complete?
    assert_empty step.errors
  end

  def test_incomplete_when_not_installed
    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?(".oh-my-zsh") })
  end

  def test_run_clones_repo_into_home
    build_step.run

    assert_includes @system.commands, "git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git #{@home}/.oh-my-zsh"
  end

  def test_run_records_error_on_clone_failure
    @system.stub(/git clone/, output: "boom", status: 1)

    step = build_step
    step.run

    assert(step.errors.any? { |e| e.include?("boom") })
  end

  private

  def build_step
    Dotfiles::Step::InstallOhMyZshStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: @home,
      system: @system
    )
  end
end
