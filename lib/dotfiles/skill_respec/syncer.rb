class Dotfiles
  module SkillRespec
    HARNESSES = [ClaudeHarness, OpencodeHarness].freeze

    Change = Data.define(:harness, :dir, :skill, :action)

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
          harness.managed_dirs.each do |dir|
            names = harness.names_for(dir, targeted)
            changes.concat(writes(harness, dir, targeted, names))
            changes.concat(prunes(harness, dir, names))
            if Manifest.read(dir, system: @system) != names.sort
              changes << Change.new(harness: harness.key, dir: dir, skill: nil, action: :manifest)
            end
          end
        end
        changes
      end

      def writes(harness, dir, targeted, names)
        names.filter_map do |name|
          definition = targeted.find { |candidate| candidate.name == name }
          next if current_content(harness, dir, name) == harness.content_for(dir, definition)
          Change.new(harness: harness.key, dir: dir, skill: name, action: :write)
        end
      end

      def prunes(harness, dir, names)
        Manifest.read(dir, system: @system).reject { |name| names.include?(name) }.filter_map do |name|
          path = harness.prune_path(dir, name)
          next unless @system.file_exist?(path) || @system.symlink?(path)
          Change.new(harness: harness.key, dir: dir, skill: name, action: :prune)
        end
      end

      def current_content(harness, dir, name)
        return nil if @system.symlink?(harness.prune_path(dir, name))
        path = harness.path_for(dir, name)
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
            write_artifact(harness, change)
          when :prune
            @system.rm_rf(harness.prune_path(change.dir, change.skill))
          when :manifest
            targeted = definitions.select { |definition| definition.targets?(change.harness) }
            Manifest.write(change.dir, harness.names_for(change.dir, targeted), system: @system)
          end
        end
      end

      def write_artifact(harness, change)
        dir, name = change.dir, change.skill
        prune_path = harness.prune_path(dir, name)
        if @system.symlink?(prune_path) || (@system.file_exist?(prune_path) && !@system.dir_exist?(prune_path))
          @system.rm_rf(prune_path)
        end
        definition = definitions.find { |candidate| candidate.name == name }
        @system.mkdir_p(File.dirname(harness.path_for(dir, name)))
        @system.write_file(harness.path_for(dir, name), harness.content_for(dir, definition))
      end
    end
  end
end
