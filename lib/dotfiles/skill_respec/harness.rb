require "yaml"

class Dotfiles
  module SkillRespec
    class Harness
      def initialize(system:, home:)
        @system, @home = system, home
      end

      def key
        raise NotImplementedError
      end

      def cli_binary
        raise NotImplementedError
      end

      def skills_dir
        raise NotImplementedError
      end

      def installed?
        _output, status = @system.execute("command -v #{cli_binary} >/dev/null 2>&1")
        status == 0
      end

      def managed_dirs
        [skills_dir]
      end

      def names_for(dir, targeted)
        targeted.map(&:name)
      end

      def path_for(dir, name)
        File.join(dir, name, "SKILL.md")
      end

      def prune_path(dir, name)
        File.join(dir, name)
      end

      def content_for(dir, definition)
        render(definition)
      end

      def render(definition)
        yaml = YAML.dump(definition.frontmatter_for(key)).sub(/\A---\n/, "")
        "---\n#{yaml}---\n\n#{definition.body}\n"
      end
    end
  end
end
