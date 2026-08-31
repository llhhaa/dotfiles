require "yaml"

class Dotfiles
  module SkillRespec
    class OpencodeHarness < Harness
      def key
        "opencode"
      end

      def cli_binary
        "opencode"
      end

      def skills_dir
        File.join(@home, ".config", "opencode", "skills")
      end

      def command_dir
        File.join(@home, ".config", "opencode", "command")
      end

      def managed_dirs
        [skills_dir, command_dir]
      end

      def names_for(dir, targeted)
        return targeted.map(&:name) if dir == skills_dir
        targeted
          .select { |definition| definition.frontmatter_for(key)["slash"] == true }
          .map(&:name)
      end

      def path_for(dir, name)
        return super if dir == skills_dir
        File.join(dir, "#{name}.md")
      end

      def prune_path(dir, name)
        return super if dir == skills_dir
        File.join(dir, "#{name}.md")
      end

      def content_for(dir, definition)
        return super if dir == skills_dir
        command_render(definition)
      end

      private

      def command_render(definition)
        yaml = YAML.dump({"description" => definition.description}).sub(/\A---\n/, "")
        "---\n#{yaml}---\n\n#{definition.body}\n"
      end
    end
  end
end
