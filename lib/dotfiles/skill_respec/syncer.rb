class Dotfiles
  module SkillRespec
    HARNESSES = [ClaudeHarness, OpencodeHarness].freeze

    Change = Data.define(:harness, :skill, :action)

    class Syncer
      def initialize(skills_dir:, harnesses:, system:)
        @skills_dir, @harnesses, @system = skills_dir, harnesses, system
      end

      def call
        changes = pending_changes
        apply(changes)
        changes
      end

      def drift?
        !pending_changes.empty?
      end

      def definitions
        @definitions ||= @system.glob(File.join(@skills_dir, "*", "SKILL.md")).sort.map do |path|
          Definition.load(path, system: @system)
        end
      end

      private

      def pending_changes
        changes = []
        @harnesses.each do |harness|
          unless harness.installed?
            Dotfiles.debug("skill-respec: skipping #{harness.key} (#{harness.cli_binary} not installed)")
            next
          end
          targeted = definitions.select { |definition| definition.targets?(harness.key) }
          names = targeted.map(&:name)
          changes.concat(writes(harness, targeted))
          changes.concat(prunes(harness, names))
          if Manifest.read(harness.skills_dir, system: @system) != names.sort
            changes << Change.new(harness: harness.key, skill: nil, action: :manifest)
          end
        end
        changes
      end

      def writes(harness, targeted)
        targeted.filter_map do |definition|
          rendered = harness.render(definition)
          next if current_content(harness, definition) == rendered
          Change.new(harness: harness.key, skill: definition.name, action: :write)
        end
      end

      def prunes(harness, names)
        Manifest.read(harness.skills_dir, system: @system).reject { |name| names.include?(name) }.filter_map do |name|
          dir = harness.skill_dir(name)
          next unless @system.file_exist?(dir) || @system.symlink?(dir)
          Change.new(harness: harness.key, skill: name, action: :prune)
        end
      end

      def current_content(harness, definition)
        return nil if @system.symlink?(harness.skill_dir(definition.name))
        path = harness.skill_path(definition.name)
        return nil unless @system.file_exist?(path)
        @system.read_file(path)
      rescue Errno::EISDIR, Errno::ENOENT, Errno::EACCES
        nil
      end

      def apply(changes)
        harness_by_key = @harnesses.to_h { |harness| [harness.key, harness] }
        changes.each do |change|
          harness = harness_by_key.fetch(change.harness)
          case change.action
          when :write
            write_skill(harness, change.skill)
          when :prune
            @system.rm_rf(harness.skill_dir(change.skill))
          when :manifest
            Manifest.write(harness.skills_dir, targeted_names(change.harness), system: @system)
          end
        end
      end

      def write_skill(harness, name)
        definition = definitions.find { |candidate| candidate.name == name }
        dir = harness.skill_dir(name)
        if @system.symlink?(dir) || (@system.file_exist?(dir) && !@system.dir_exist?(dir))
          @system.rm_rf(dir)
        end
        @system.mkdir_p(dir)
        @system.write_file(harness.skill_path(name), harness.render(definition))
      end

      def targeted_names(harness_key)
        definitions.select { |definition| definition.targets?(harness_key) }.map(&:name)
      end
    end
  end
end
