class Dotfiles::Step::SymlinkDotfilesStep < Dotfiles::Step
  def complete?
    super
    symlinks.each { |entry| validate(entry, examine(entry)) }
    @errors.empty?
  end

  def run
    symlinks.each { |entry| ensure_symlink(entry, examine(entry)) }
  end

  private

  def examine(entry)
    is_symlink = @system.symlink?(entry[:dest])
    {
      src_exists: @system.file_exist?(entry[:src]),
      dest_is_symlink: is_symlink,
      dest_target: is_symlink ? @system.readlink(entry[:dest]) : nil,
      dest_is_file: !is_symlink && @system.file_exist?(entry[:dest])
    }
  end

  def validate(entry, state)
    if !state[:src_exists]
      add_error("Source missing: #{entry[:src]}")
    elsif !correct?(entry, state)
      add_error(describe_problem(entry, state))
    end
  end

  def ensure_symlink(entry, state)
    return unless state[:src_exists]
    @system.mkdir_p(File.dirname(entry[:dest]))
    handle_existing(entry, state)
    @system.create_symlink(entry[:src], entry[:dest])
  end

  def handle_existing(entry, state)
    if state[:dest_is_symlink]
      @system.rm_rf(entry[:dest])
    elsif state[:dest_is_file]
      backup(entry)
    end
  end

  def backup(entry)
    backup_path = "#{entry[:dest]}.bak"
    @system.mv(entry[:dest], backup_path)
    add_notice(title: "Backed up existing file", message: "#{entry[:dest]} → #{backup_path}")
  end

  def correct?(entry, state)
    state[:dest_is_symlink] && state[:dest_target] == entry[:src]
  end

  def describe_problem(entry, state)
    if state[:dest_is_symlink]
      "#{entry[:dest]} → #{state[:dest_target]}, expected #{entry[:src]}"
    elsif state[:dest_is_file]
      "#{entry[:dest]} exists and is not a symlink"
    else
      "#{entry[:dest]} is not symlinked"
    end
  end

  def symlinks
    @config.fetch("symlinks", []).map { |entry| build_entry(entry) }
  end

  def build_entry(entry)
    {
      src: File.expand_path(File.join(@dotfiles_dir, entry["src"])),
      dest: expand_path_with_home(entry["dest"])
    }
  end
end
