require_relative "../../test_helper"

class SkillRespecSyncerTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir("skill-respec-")
    @home = File.join(@root, "home")
    @sources = File.join(@root, "skills")
    FileUtils.mkdir_p([@home, @sources])

    write_source("handoff", <<~FRONTMATTER)
      name: handoff
      description: Compact the conversation.
      opencode:
        slash: true
    FRONTMATTER
    write_source("pickup", "name: pickup\ndescription: Resume work from a handoff.\nharnesses: [opencode]\n")
  end

  def teardown
    FileUtils.rm_rf(@root)
  end

  def test_writes_targeted_skills_to_installed_harness
    changes = build_syncer.call

    written = changes.select { |change| change.action == :write && change.dir == opencode_skills }.map(&:skill)
    assert_equal %w[handoff pickup], written.sort
    assert_equal expected_skill(handoff_frontmatter, "handoff body."), File.read(skill_path(opencode_skills, "handoff"))
    assert_equal expected_skill(pickup_frontmatter, "pickup body."), File.read(skill_path(opencode_skills, "pickup"))
  end

  def test_skips_uninstalled_harness_entirely
    build_syncer.call

    refute File.exist?(claude_skills), "uninstalled harness should leave no skills dir"
    refute File.exist?(manifest_path(claude_skills))
  end

  def test_claude_harness_manages_skills_only
    syncer = build_syncer(claude: 0)
    syncer.call

    assert File.exist?(skill_path(claude_skills, "handoff"))
    refute File.exist?(File.join(@home, ".claude", "commands"))
  end

  def test_exclusive_skill_not_written_to_other_harness
    syncer = build_syncer(claude: 0)
    syncer.call

    refute File.exist?(skill_path(claude_skills, "pickup"))
    assert File.exist?(skill_path(claude_skills, "handoff"))
  end

  def test_harness_specific_frontmatter
    syncer = build_syncer(claude: 0)
    syncer.call

    assert_includes File.read(skill_path(opencode_skills, "handoff")), "slash: true"
    refute_includes File.read(skill_path(claude_skills, "handoff")), "slash"
  end

  def test_generates_command_file_for_slash_skills
    build_syncer.call

    assert_equal expected_command("Compact the conversation.", "handoff body."), File.read(command_path("handoff"))
    refute File.exist?(command_path("pickup")), "non-slash skill should not get a command"
  end

  def test_writes_command_manifest
    build_syncer.call

    assert_equal %w[handoff], JSON.parse(File.read(manifest_path(command_dir)))
  end

  def test_overwrites_drifted_command
    FileUtils.mkdir_p(command_dir)
    File.write(command_path("handoff"), "hand-edited content")

    build_syncer.call

    assert_equal expected_command("Compact the conversation.", "handoff body."), File.read(command_path("handoff"))
  end

  def test_prunes_command_when_slash_removed
    write_source("handoff", "name: handoff\ndescription: Compact the conversation.\n")
    write_manifest(command_dir, %w[handoff])
    FileUtils.mkdir_p(command_dir)
    File.write(command_path("handoff"), "stale command")

    build_syncer.call

    refute File.exist?(command_path("handoff"))
    assert File.exist?(skill_path(opencode_skills, "handoff")), "skill copy should survive slash removal"
  end

  def test_overwrites_drifted_skill_with_same_name
    dir = File.join(opencode_skills, "handoff")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "SKILL.md"), "hand-edited content")

    build_syncer.call

    assert_equal expected_skill(handoff_frontmatter, "handoff body."), File.read(File.join(dir, "SKILL.md"))
  end

  def test_replaces_symlinked_skill_dir
    dest = File.join(opencode_skills, "handoff")
    FileUtils.mkdir_p(opencode_skills)
    File.symlink(File.join(@sources, "handoff"), dest)

    build_syncer.call

    refute File.symlink?(dest), "skill dir should be a real directory, not a symlink"
    assert_equal expected_skill(handoff_frontmatter, "handoff body."), File.read(File.join(dest, "SKILL.md"))
  end

  def test_leaves_foreign_skills_untouched
    foreign = write_dest_skill(opencode_skills, "assay", "foreign content")

    build_syncer.call

    assert_equal "foreign content", File.read(foreign)
    refute_includes JSON.parse(File.read(manifest_path(opencode_skills))), "assay"
  end

  def test_prunes_manifest_orphans
    write_manifest(opencode_skills, %w[handoff pickup ghost])
    ghost = write_dest_skill(opencode_skills, "ghost", "stale content")

    changes = build_syncer.call

    refute File.exist?(ghost)
    assert File.exist?(skill_path(opencode_skills, "handoff"))
    assert_includes changes.map(&:skill), "ghost"
    assert_equal %w[handoff pickup], JSON.parse(File.read(manifest_path(opencode_skills)))
  end

  def test_prunes_skill_retargeted_away_from_harness
    write_source("handoff", "name: handoff\ndescription: Compact the conversation.\nharnesses: [opencode]\n")
    write_manifest(claude_skills, %w[handoff])
    write_dest_skill(claude_skills, "handoff", "stale claude copy")

    syncer = build_syncer(claude: 0)
    changes = syncer.call

    refute File.exist?(skill_path(claude_skills, "handoff"))
    assert changes.any? { |change| change.action == :prune && change.skill == "handoff" }
  end

  def test_writes_sorted_manifest
    build_syncer.call

    assert_equal <<~JSON, File.read(manifest_path(opencode_skills))
      [
        "handoff",
        "pickup"
      ]
    JSON
  end

  def test_drift_true_before_first_sync
    assert build_syncer.drift?
  end

  def test_idempotent_on_second_call
    syncer = build_syncer
    syncer.call

    assert_empty syncer.call
    refute syncer.drift?
  end

  private

  def claude_skills
    File.join(@home, ".claude", "skills")
  end

  def opencode_skills
    File.join(@home, ".config", "opencode", "skills")
  end

  def command_dir
    File.join(@home, ".config", "opencode", "command")
  end

  def command_path(name)
    File.join(command_dir, "#{name}.md")
  end

  def skill_path(skills_dir, name)
    File.join(skills_dir, name, "SKILL.md")
  end

  def manifest_path(skills_dir)
    File.join(skills_dir, Dotfiles::SkillRespec::Manifest::FILENAME)
  end

  def build_syncer(claude: 1, opencode: 0)
    system = FakeSystem.new
    system.stub(/command -v claude/, status: claude)
    system.stub(/command -v opencode/, status: opencode)
    Dotfiles::SkillRespec::Syncer.new(
      skills_dir: @sources,
      harnesses: [
        Dotfiles::SkillRespec::ClaudeHarness.new(system: system, home: @home),
        Dotfiles::SkillRespec::OpencodeHarness.new(system: system, home: @home)
      ],
      system: system
    )
  end

  def write_source(name, frontmatter)
    dir = File.join(@sources, name)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "SKILL.md"), "---\n#{frontmatter}---\n\n#{name} body.\n")
  end

  def write_dest_skill(skills_dir, name, content)
    path = skill_path(skills_dir, name)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def write_manifest(skills_dir, names)
    FileUtils.mkdir_p(skills_dir)
    File.write(manifest_path(skills_dir), JSON.pretty_generate(names.sort) + "\n")
  end

  def expected_skill(frontmatter, body)
    "---\n#{frontmatter}---\n\n#{body}\n"
  end

  def expected_command(description, body)
    "---\ndescription: #{description}\n---\n\n#{body}\n"
  end

  def handoff_frontmatter
    "name: handoff\ndescription: Compact the conversation.\nslash: true\n"
  end

  def pickup_frontmatter
    "name: pickup\ndescription: Resume work from a handoff.\n"
  end
end
