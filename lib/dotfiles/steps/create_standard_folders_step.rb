class Dotfiles::Step::CreateStandardFoldersStep < Dotfiles::Step
  def complete?
    super
    folders.each { |folder| add_error("Folder missing: #{folder}") unless @system.dir_exist?(folder) }
    @errors.empty?
  end

  def run
    folders.each { |folder| @system.mkdir_p(folder) }
  end

  private

  def folders
    @config.standard_folders.map { |path| expand_path_with_home(path) }
  end
end
