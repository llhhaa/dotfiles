require "json"

class Dotfiles
  module SkillRespec
    class Manifest
      FILENAME = ".skill-respec.json"

      def self.read(skills_dir, system:)
        path = File.join(skills_dir, FILENAME)
        return [] unless system.file_exist?(path)
        JSON.parse(system.read_file(path))
      rescue JSON::ParserError, Errno::EISDIR
        []
      end

      def self.write(skills_dir, names, system:)
        system.mkdir_p(skills_dir)
        system.write_file(File.join(skills_dir, FILENAME), content(names))
      end

      def self.content(names)
        JSON.pretty_generate(names.sort) + "\n"
      end
    end
  end
end
