require "json"
require "tmpdir"

class Dotfiles::Step::InstallNonAptPackagesStep < Dotfiles::Step
  debian_only

  Package = Data.define(:name, :repo, :asset_glob, :command)

  def self.depends_on
    [Dotfiles::Step::InstallAptSourcesStep]
  end

  def complete?
    super
    missing.each { |pkg| add_error("Command not found: #{pkg.command}") }
    @errors.empty?
  end

  def run
    missing.each { |pkg| install(pkg) }
  end

  private

  def packages
    @config.debian_non_apt_packages.map do |raw|
      name = raw.fetch("name")
      Package.new(name: name, repo: raw.fetch("repo"), asset_glob: raw.fetch("asset_glob"), command: raw["command"] || name)
    end
  end

  def missing
    packages.reject { |pkg| command_exists?(pkg.command) }
  end

  def install(pkg)
    asset = find_asset(pkg)
    if asset.nil?
      add_error("No release asset matching '#{pattern(pkg)}' in #{pkg.repo}")
      return
    end

    output, status = execute("curl -fsSL -o #{deb_path(pkg)} #{asset["browser_download_url"]}")
    unless status == 0
      add_error("Failed to download #{pkg.name}: #{output}")
      return
    end

    output, status = execute("#{sudo}apt-get install -y #{deb_path(pkg)}")
    add_error("Failed to install #{pkg.name}: #{output}") unless status == 0
  end

  def find_asset(pkg)
    output, status = execute("curl -fsSL #{api_url(pkg)}")
    return nil unless status == 0

    release = JSON.parse(output)
    release.fetch("assets", []).find { |asset| File.fnmatch?(pattern(pkg), asset["name"]) }
  rescue JSON::ParserError
    nil
  end

  def api_url(pkg)
    "https://api.github.com/repos/#{pkg.repo}/releases/latest"
  end

  def pattern(pkg)
    pkg.asset_glob
      .gsub("{arch}", architecture)
      .gsub("{os_version}", os_version)
  end

  def deb_path(pkg)
    File.join(Dir.tmpdir, "#{pkg.name}.deb")
  end

  def architecture
    @architecture ||= begin
      output, status = execute("dpkg --print-architecture")
      status == 0 ? output.strip : "amd64"
    end
  end

  def os_version
    @os_version ||= begin
      output, status = execute(". /etc/os-release && echo $VERSION_ID")
      status == 0 ? output.strip : ""
    end
  end
end
