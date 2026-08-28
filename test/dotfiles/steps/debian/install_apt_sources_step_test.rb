require_relative "../../../test_helper"

class InstallAptSourcesStepTest < Minitest::Test
  KEYRING = "/usr/share/keyrings/gierens-archive-keyring.gpg"
  LIST = "/etc/apt/sources.list.d/gierens.list"
  EXPECTED_LINE = "deb [signed-by=#{KEYRING}] http://deb.gierens.de stable main"

  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @home = Dir.mktmpdir("home-")
    @system = StubbedFS.new
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
    FileUtils.rm_rf(@home)
  end

  def test_incomplete_when_keyring_and_list_missing
    write_structured_source

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("Keyring missing") })
    assert(step.errors.any? { |e| e.include?("gierens") })
  end

  def test_incomplete_when_list_content_mismatches
    write_structured_source
    @system.write(KEYRING, "")
    @system.write(LIST, "deb http://old.example.com stable main\n")

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("mismatched") })
  end

  def test_complete_when_keyring_and_list_present
    write_structured_source
    @system.write(KEYRING, "")
    @system.write(LIST, "#{EXPECTED_LINE}\n")

    step = build_step
    assert step.complete?
    assert_empty step.errors
  end

  def test_run_dearmors_armored_keys_and_writes_list
    write_structured_source

    build_step.run

    assert_includes @system.commands, "curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o #{KEYRING}"
    assert_includes @system.commands, "echo '#{EXPECTED_LINE}' | sudo tee #{LIST}"
  end

  def test_run_copies_binary_keys_without_dearmor
    write_source(
      "name" => "azlux",
      "repo" => "http://packages.azlux.fr/debian/",
      "suite" => "stable",
      "components" => ["main"],
      "key_url" => "https://azlux.fr/repo.gpg"
    )

    build_step.run

    assert_includes @system.commands, "curl -fsSL https://azlux.fr/repo.gpg | sudo tee /usr/share/keyrings/azlux-archive-keyring.gpg > /dev/null"
  end

  def test_run_writes_line_style_source_verbatim
    write_source(
      "name" => "mise",
      "line" => "deb [signed-by=/usr/share/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main",
      "key_url" => "https://mise.jdx.dev/gpg-key.pub"
    )

    build_step.run

    assert_includes @system.commands, "echo 'deb [signed-by=/usr/share/keyrings/mise-archive-keyring.gpg] https://mise.jdx.dev/deb stable main' | sudo tee /etc/apt/sources.list.d/mise.list"
  end

  def test_run_records_error_when_key_install_fails
    write_structured_source
    @system.stub(/curl -fsSL.*gierens/, output: "key boom", status: 22)

    step = build_step
    step.run

    assert(step.errors.any? { |e| e.include?("key boom") })
  end

  private

  def build_step
    Dotfiles::Step::InstallAptSourcesStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: @home,
      system: @system
    )
  end

  def write_structured_source
    write_source(
      "name" => "gierens",
      "repo" => "http://deb.gierens.de",
      "suite" => "stable",
      "components" => ["main"],
      "key_url" => "https://raw.githubusercontent.com/eza-community/eza/main/deb.asc"
    )
  end

  def write_source(source)
    config_dir = File.join(@dotfiles_dir, "config")
    FileUtils.mkdir_p(config_dir)
    File.write(File.join(config_dir, "config.yml"), {"debian_sources" => [source]}.to_yaml)
  end

  class StubbedFS < FakeSystem
    def initialize
      super
      @files = {}
      @contents = {}
    end

    def write(path, content)
      @files[path] = true
      @contents[path] = content
    end

    def file_exist?(path)
      return @files.fetch(path, false) if @files.key?(path) || known_system_path?(path)
      super
    end

    def read_file(path)
      return @contents[path] if @contents.key?(path)
      super
    end

    private

    def known_system_path?(path)
      path.start_with?("/usr/share/keyrings/", "/etc/apt/sources.list.d/")
    end
  end
end
