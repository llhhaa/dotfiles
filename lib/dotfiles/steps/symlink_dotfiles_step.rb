class Dotfiles::Step::SymlinkDotfilesStep < Dotfiles::Step
  Entry = Data.define(:src, :dest)
  Survey = Data.define(:src_exists, :dest_is_symlink, :dest_target, :dest_is_file)

  def complete?
    super
    symlinks.each { |entry| validate(entry, survey(entry)) }
    @errors.empty?
  end

  def run
    symlinks.each { |entry| ensure_symlink(entry, survey(entry)) }
  end

  private

  def survey(entry)
    is_symlink = @system.symlink?(entry.dest)
    Survey.new(
      src_exists: @system.file_exist?(entry.src),
      dest_is_symlink: is_symlink,
      dest_target: is_symlink ? @system.readlink(entry.dest) : nil,
      dest_is_file: !is_symlink && @system.file_exist?(entry.dest)
    )
  end

  def validate(entry, survey)
    if !survey.src_exists
      add_error("Source missing: #{entry.src}")
    elsif !correct?(entry, survey)
      add_error(describe_problem(entry, survey))
    end
  end

  def ensure_symlink(entry, survey)
    return unless survey.src_exists
    @system.mkdir_p(File.dirname(entry.dest))
    handle_existing(entry, survey)
    @system.create_symlink(entry.src, entry.dest)
  end

  def handle_existing(entry, survey)
    if survey.dest_is_symlink
      @system.rm_rf(entry.dest)
    elsif survey.dest_is_file
      backup(entry)
    end
  end

  def backup(entry)
    backup_path = "#{entry.dest}.bak"
    @system.mv(entry.dest, backup_path)
    add_notice(title: "Backed up existing file", message: "#{entry.dest} → #{backup_path}")
  end

  def correct?(entry, survey)
    survey.dest_is_symlink && survey.dest_target == entry.src
  end

  def describe_problem(entry, survey)
    if survey.dest_is_symlink
      "#{entry.dest} → #{survey.dest_target}, expected #{entry.src}"
    elsif survey.dest_is_file
      "#{entry.dest} exists and is not a symlink"
    else
      "#{entry.dest} is not symlinked"
    end
  end

  def symlinks
    @config.fetch("symlinks", []).map { |raw| build_entry(raw) }
  end

  def build_entry(raw)
    Entry.new(
      src: File.expand_path(File.join(@dotfiles_dir, raw["src"])),
      dest: expand_path_with_home(raw["dest"])
    )
  end
end
