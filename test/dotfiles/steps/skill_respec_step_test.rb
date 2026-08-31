require_relative "../../test_helper"

class SkillRespecStepTest < Minitest::Test
  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @home = Dir.mktmpdir("home-")

    config_dir = File.join(@dotfiles_dir, "config")
    FileUtils.mkdir_p(config_dir)
    File.write(File.join(config_dir, "config.yml"), {"symlinks" => []}.to_yaml)

    skills_dir = File.join(@dotfiles_dir, "skills", "handoff")
    FileUtils.mkdir_p(skills_dir)
    File.write(File.join(skills_dir, "SKILL.md"), <<~SKILL)
      ---
      name: handoff
      description: Compact the conversation.
      opencode:
        slash: true
      ---

      Body.
    SKILL

    @system = FakeSystem.new
    @system.stub(/command -v claude/, status: 1)
    @system.stub(/command -v opencode/, status: 0)
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
    FileUtils.rm_rf(@home)
  end

  def test_incomplete_when_skills_out_of_sync
    step = build_step

    refute step.complete?
    assert(step.errors.any? { |error| error.include?("out of sync") })
  end

  def test_run_writes_skills_for_installed_harness
    step = build_step
    step.run

    assert File.exist?(File.join(@home, ".config", "opencode", "skills", "handoff", "SKILL.md"))
    assert(step.notices.any? { |notice| notice[:title] == "Wrote skill" })
    assert step.complete?
  end

  def test_run_skips_uninstalled_harness
    step = build_step
    step.run

    refute File.exist?(File.join(@home, ".claude", "skills"))
  end

  def test_run_is_idempotent
    step = build_step
    step.run
    step.reset_state

    step.run

    assert_empty step.notices
    assert step.complete?
  end

  def test_depends_on_symlink_step
    assert_includes Dotfiles::Step::SkillRespecStep.depends_on, Dotfiles::Step::SymlinkDotfilesStep
  end

  private

  def build_step
    Dotfiles::Step::SkillRespecStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: @home,
      system: @system
    )
  end
end
