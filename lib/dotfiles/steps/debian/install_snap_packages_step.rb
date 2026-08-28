class Dotfiles::Step::InstallSnapPackagesStep < Dotfiles::Step
  debian_only

  def complete?
    super
    missing.each { |name| add_error("Snap not installed: #{name}") }
    @errors.empty?
  end

  def run
    missing.each { |name| install(name) }
  end

  private

  def snaps
    @config.debian_snap_packages.map { |raw| raw.is_a?(Hash) ? raw.fetch("name") : raw }
  end

  def missing
    snaps - installed
  end

  def installed
    output, status = execute("snap list")
    return [] unless status == 0
    output.split("\n").drop(1).map { |line| line.split(/\s+/).first }.compact
  end

  def install(name)
    output, status = execute("#{sudo}snap install #{name}")
    add_error("Failed to install snap #{name}: #{output}") unless status == 0
  end
end
