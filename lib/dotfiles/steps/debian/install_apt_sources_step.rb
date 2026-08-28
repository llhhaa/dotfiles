class Dotfiles::Step::InstallAptSourcesStep < Dotfiles::Step
  debian_only

  Source = Data.define(:name, :key_url, :repo, :suite, :components, :line)

  def complete?
    super
    sources.each { |source| validate(source) }
    @errors.empty?
  end

  def run
    sources.each { |source| install(source) }
  end

  private

  def sources
    @config.debian_sources.map do |raw|
      Source.new(
        name: raw.fetch("name"),
        key_url: raw.fetch("key_url"),
        repo: raw["repo"],
        suite: raw["suite"],
        components: raw["components"],
        line: raw["line"]
      )
    end
  end

  def validate(source)
    if !@system.file_exist?(keyring_path(source))
      add_error("Keyring missing for #{source.name}: #{keyring_path(source)}")
    elsif !list_file_correct?(source)
      add_error("Apt source #{source.name} missing or mismatched: #{list_path(source)}")
    end
  end

  def install(source)
    install_key(source)
    write_list(source)
  end

  def install_key(source)
    command = if source.key_url.end_with?(".gpg")
      "curl -fsSL #{source.key_url} | #{sudo}tee #{keyring_path(source)} > /dev/null"
    else
      "curl -fsSL #{source.key_url} | #{sudo}gpg --dearmor --yes -o #{keyring_path(source)}"
    end
    output, status = execute(command)
    add_error("Failed to install key for #{source.name}: #{output}") unless status == 0
  end

  def write_list(source)
    output, status = execute("echo '#{apt_line(source)}' | #{sudo}tee #{list_path(source)}")
    add_error("Failed to write apt source #{source.name}: #{output}") unless status == 0
  end

  def apt_line(source)
    return source.line if source.line
    "deb [signed-by=#{keyring_path(source)}] #{source.repo} #{source.suite} #{source.components.join(' ')}"
  end

  def list_file_correct?(source)
    return false unless @system.file_exist?(list_path(source))
    @system.read_file(list_path(source)).strip == apt_line(source)
  end

  def keyring_path(source)
    "/usr/share/keyrings/#{source.name}-archive-keyring.gpg"
  end

  def list_path(source)
    "/etc/apt/sources.list.d/#{source.name}.list"
  end
end
