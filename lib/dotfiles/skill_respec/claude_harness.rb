class Dotfiles
  module SkillRespec
    class ClaudeHarness < Harness
      def key
        "claude"
      end

      def cli_binary
        "claude"
      end

      def skills_dir
        File.join(@home, ".claude", "skills")
      end
    end
  end
end
