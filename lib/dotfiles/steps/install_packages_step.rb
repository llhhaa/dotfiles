class Dotfiles::Step::InstallPackagesStep < Dotfiles::Step
  Package = Data.define(:command, :brew, :debian)

  def self.depends_on
    [Dotfiles::Step::InstallAptSourcesStep]
  end

  def complete?
    super
    managed_missing.each { |pkg| add_error("Command not found: #{pkg.command}") }
    @errors.empty?
  end

  def run
    return if managed_missing.empty?

    refresh_package_index
    managed_missing.each { |pkg| install(pkg) }
  end

  private

  def packages
    @config.packages.map do |command, raw|
      Package.new(command: raw["command"] || command, brew: raw["brew"], debian: raw["debian"])
    end
  end

  def managed
    packages.select { |pkg| managed_on_platform?(pkg) }
  end

  def managed_missing
    managed.reject { |pkg| command_exists?(pkg.command) }
  end

  def managed_on_platform?(pkg)
    if @system.macos?
      !pkg.brew.nil?
    elsif @system.debian?
      !pkg.debian.nil?
    else
      false
    end
  end

  def refresh_package_index
    return unless @system.debian?

    output, status = execute("#{sudo}apt-get update")
    add_warning(title: "apt-get update failed", message: output) unless status == 0
  end

  def install(pkg)
    package_name = install_name(pkg)
    if package_name.nil?
      add_warning(title: "No package configured", message: "#{pkg.command} has no package name for this platform; install it manually")
      return
    end

    output, status = execute("#{install_command} #{package_name}")
    add_error("Failed to install #{pkg.command}: #{output}") unless status == 0
  end

  def install_name(pkg)
    @system.macos? ? pkg.brew : pkg.debian
  end

  def install_command
    @system.macos? ? "brew install" : "#{sudo}apt-get install -y"
  end
end
