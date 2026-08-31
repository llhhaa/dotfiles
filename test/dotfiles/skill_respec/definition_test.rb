require_relative "../../test_helper"

class SkillRespecDefinitionTest < Minitest::Test
  def test_parses_frontmatter_and_body
    definition = build_definition(<<~FRONTMATTER)
      name: handoff
      description: Compact the conversation.
      harnesses: [claude, opencode]
      opencode:
        slash: true
    FRONTMATTER

    assert_equal "handoff", definition.name
    assert_equal "Compact the conversation.", definition.description
    assert_equal "Body here.", definition.body
    assert_equal %w[claude opencode], definition.harnesses
  end

  def test_targets_every_harness_when_harnesses_unset
    definition = build_definition("name: handoff\ndescription: Compact the conversation.\n")

    assert definition.targets?("claude")
    assert definition.targets?("opencode")
  end

  def test_targets_only_listed_harnesses
    definition = build_definition("name: handoff\ndescription: Compact the conversation.\nharnesses: [claude]\n")

    assert definition.targets?("claude")
    refute definition.targets?("opencode")
  end

  def test_frontmatter_for_merges_overrides_and_strips_meta_keys
    definition = build_definition("name: handoff\ndescription: Compact the conversation.\nopencode:\n  slash: true\n")

    assert_equal(
      {"name" => "handoff", "description" => "Compact the conversation.", "slash" => true},
      definition.frontmatter_for("opencode")
    )
  end

  def test_frontmatter_for_without_override_returns_base_keys_only
    definition = build_definition("name: handoff\ndescription: Compact the conversation.\nopencode:\n  slash: true\n")

    assert_equal(
      {"name" => "handoff", "description" => "Compact the conversation."},
      definition.frontmatter_for("claude")
    )
  end

  def test_rejects_name_that_does_not_match_folder
    error = assert_raises(Dotfiles::SkillRespec::Definition::ValidationError) do
      build_definition("name: other\ndescription: Compact the conversation.\n")
    end
    assert_match(/must match folder/, error.message)
  end

  def test_rejects_missing_description
    error = assert_raises(Dotfiles::SkillRespec::Definition::ValidationError) do
      build_definition("name: handoff\n")
    end
    assert_match(/description is required/, error.message)
  end

  def test_rejects_missing_frontmatter_delimiters
    error = assert_raises(Dotfiles::SkillRespec::Definition::ValidationError) do
      Dotfiles::SkillRespec::Definition.new(folder: "handoff", content: "no frontmatter at all")
    end
    assert_match(/missing frontmatter/, error.message)
  end

  def test_rejects_override_that_sets_name
    definition = build_definition("name: handoff\ndescription: Compact the conversation.\nopencode:\n  name: other\n")

    error = assert_raises(Dotfiles::SkillRespec::Definition::ValidationError) do
      definition.frontmatter_for("opencode")
    end
    assert_match(/may not set name/, error.message)
  end

  def test_rejects_non_mapping_override
    definition = build_definition("name: handoff\ndescription: Compact the conversation.\nopencode: true\n")

    error = assert_raises(Dotfiles::SkillRespec::Definition::ValidationError) do
      definition.frontmatter_for("opencode")
    end
    assert_match(/must be a mapping/, error.message)
  end

  def test_rejects_non_list_harnesses
    error = assert_raises(Dotfiles::SkillRespec::Definition::ValidationError) do
      build_definition("name: handoff\ndescription: Compact the conversation.\nharnesses: claude\n")
    end
    assert_match(/list of strings/, error.message)
  end

  private

  def build_definition(frontmatter)
    Dotfiles::SkillRespec::Definition.new(
      folder: "handoff",
      content: "---\n#{frontmatter}---\n\nBody here.\n"
    )
  end
end
