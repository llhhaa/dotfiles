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
    end
  end
end
