require_relative "../../test_helper"

class SymlinkDotfilesStepTest < Minitest::Test
  def setup
    @dotfiles_dir = Dir.mktmpdir("dotfiles-")
    @home = Dir.mktmpdir("home-")
    File.write(source_path, "managed content")
    write_config([{src: "rcfile", dest: dest_path}])
  end

  def teardown
    FileUtils.rm_rf(@dotfiles_dir)
    FileUtils.rm_rf(@home)
  end

  def test_creates_symlink_when_destination_missing
    build_step.run
    assert File.symlink?(dest_path)
    assert_equal source_path, File.readlink(dest_path)
  end

  def test_backs_up_existing_real_file
    File.write(dest_path, "user-modified content")
    step = build_step
    step.run
    assert File.symlink?(dest_path)
    assert_equal "user-modified content", File.read("#{dest_path}.bak")
    assert(step.notices.any? { |n| n[:title] == "Backed up existing file" })
  end

  def test_replaces_stale_symlink_without_backing_up
    other = File.join(@home, "other-target")
    File.write(other, "other")
    File.symlink(other, dest_path)

    build_step.run

    assert_equal source_path, File.readlink(dest_path)
    refute File.exist?("#{dest_path}.bak"), "stale symlink should be removed, not backed up"
    assert File.exist?(other), "stale symlink replacement must not touch the previous target"
  end

  def test_run_creates_parent_directories
    nested = File.join(@home, ".config", "nested", "rcfile")
    write_config([{src: "rcfile", dest: nested}])

    build_step.run

    assert File.symlink?(nested)
  end

  def test_complete_is_true_when_already_symlinked_correctly
    File.symlink(source_path, dest_path)
    step = build_step
    assert step.complete?
    assert_empty step.errors
  end

  def test_complete_reports_real_file_at_destination
    File.write(dest_path, "content")
    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("not a symlink") })
  end

  def test_complete_reports_stale_symlink
    other = File.join(@home, "other-target")
    File.write(other, "x")
    File.symlink(other, dest_path)

    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("expected") })
  end

  def test_complete_reports_missing_source
    File.unlink(source_path)
    step = build_step
    refute step.complete?
    assert(step.errors.any? { |e| e.include?("Source missing") })
  end

  def test_run_skips_when_source_missing
    File.unlink(source_path)
    build_step.run
    refute File.exist?(dest_path)
    refute File.symlink?(dest_path)
  end

  def test_expands_tilde_in_dest_path
    write_config([{src: "rcfile", dest: "~/.tilde-rcfile"}])

    build_step.run

    expanded = File.join(@home, ".tilde-rcfile")
    assert File.symlink?(expanded)
    assert_equal source_path, File.readlink(expanded)
  end

  def test_backup_notice_reaches_output_formatter
    File.write(dest_path, "user content")
    step = build_step
    step.run

    system_calls = []
    recording_formatter(
      {failed_steps: [], table_data: [], warnings: [], notices: step.notices, errors: []},
      system_calls: system_calls
    ).display

    rendered = system_calls.find { |args| args.include?("Backed up existing file") }
    refute_nil rendered, "backup notice never reached system_call"
    assert(rendered.any? { |a| a.is_a?(String) && a.include?(dest_path) })
  end

  private

  def source_path
    File.join(@dotfiles_dir, "rcfile")
  end

  def dest_path
    File.join(@home, ".rcfile")
  end

  def build_step
    Dotfiles::Step::SymlinkDotfilesStep.new(
      debug: false,
      dotfiles_repo: "irrelevant",
      dotfiles_dir: @dotfiles_dir,
      home: @home
    )
  end

  def write_config(symlinks)
    config_dir = File.join(@dotfiles_dir, "config")
    FileUtils.mkdir_p(config_dir)
    payload = {"symlinks" => symlinks.map { |e| {"src" => e[:src], "dest" => e[:dest]} }}
    File.write(File.join(config_dir, "config.yml"), payload.to_yaml)
  end
end
