class Dotfiles::Step::InstallBrewCasksStep < Dotfiles::Step
  macos_only

  def complete?
    super
    missing_casks.each { |cask| add_error("Cask not installed: #{cask}") }
    @errors.empty?
  end

  def run
    missing_casks.each { |cask| install(cask) }
  end

  private

  def missing_casks
    return [] if declared_casks.empty?
    declared_casks - installed_casks
  end

  def installed_casks
    output, status = execute("brew list --cask")
    return [] unless status == 0
    output.split("\n").map(&:strip).reject(&:empty?)
  end

  def install(cask)
    output, status = execute("brew install --cask #{cask}")
    add_error("Failed to install #{cask}: #{output}") unless status == 0
  end

  def declared_casks
    @config.brew_casks
  end
end
