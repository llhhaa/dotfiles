require "yaml"

class Dotfiles
  module SkillRespec
    class Definition
      ValidationError = Class.new(StandardError)

      FRONTMATTER_PATTERN = /\A---\r?\n(.*?)\r?\n---\r?\n(.*)\z/m

      attr_reader :name, :description, :body, :harnesses

      def self.load(path, system:)
        new(folder: File.basename(File.dirname(path)), content: system.read_file(path))
      end

      def initialize(folder:, content:)
        frontmatter, body = split(content)
        @frontmatter = frontmatter
        @name = frontmatter["name"]
        @description = frontmatter["description"]
        @harnesses = frontmatter["harnesses"]
        @body = body
        validate!(folder)
      end

      def targets?(harness_key)
        @harnesses.nil? || @harnesses.include?(harness_key)
      end

      def frontmatter_for(harness_key)
        base = {"name" => @name, "description" => @description}
        case @frontmatter[harness_key]
        when nil
          base
        when Hash
          override = @frontmatter.fetch(harness_key)
          raise ValidationError, "override for #{harness_key} may not set name" if override.key?("name")
          base.merge(override)
        else
          raise ValidationError, "override for #{harness_key} must be a mapping"
        end
      end

      private

      def split(content)
        match = content.match(FRONTMATTER_PATTERN)
        raise ValidationError, "missing frontmatter delimiters" unless match
        [parse_frontmatter(match[1]), match[2].sub(/\A\n+/, "").sub(/[[:space:]]+\z/, "")]
      end

      def parse_frontmatter(source)
        parsed = YAML.safe_load(source)
        raise ValidationError, "frontmatter must be a mapping" unless parsed.is_a?(Hash)
        parsed
      end

      def validate!(folder)
        raise ValidationError, "name is required" unless @name.is_a?(String)
        raise ValidationError, "name must match folder #{folder.inspect}, got #{@name.inspect}" unless @name == folder
        raise ValidationError, "description is required" unless @description.is_a?(String) && !@description.empty?
        return if @harnesses.nil?
        unless @harnesses.is_a?(Array) && @harnesses.all? { |harness| harness.is_a?(String) }
          raise ValidationError, "harnesses must be a list of strings"
        end
      end
    end
  end
end
