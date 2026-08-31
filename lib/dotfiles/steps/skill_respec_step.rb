class Dotfiles::Step::SkillRespecStep < Dotfiles::Step
  def self.depends_on
    [Dotfiles::Step::SymlinkDotfilesStep]
  end

  def complete?
    super
    if syncer.drift?
      add_error("Skills in #{sources_dir} are out of sync with installed harnesses")
    end
    @errors.empty?
  end

  def run
    syncer.call.each do |change|
      next if change.action == :manifest
      verb = change.action == :write ? "Wrote" : "Pruned"
      add_notice(title: "#{verb} skill", message: "#{change.skill} (#{change.harness})")
    end
  end

  private

  def syncer
    @syncer ||= Dotfiles::SkillRespec::Syncer.new(
      skills_dir: sources_dir,
      harnesses: Dotfiles::SkillRespec::HARNESSES.map { |harness| harness.new(system: @system, home: @home) },
      system: @system
    )
  end

  def sources_dir
    File.join(@dotfiles_dir, "skills")
  end
end
