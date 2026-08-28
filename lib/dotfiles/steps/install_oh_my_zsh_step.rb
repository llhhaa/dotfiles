class Dotfiles::Step::InstallOhMyZshStep < Dotfiles::Step
  OH_MY_ZSH_URL = "https://github.com/ohmyzsh/ohmyzsh.git"
  INSTALL_DIR = ".oh-my-zsh"

  def complete?
    super
    add_error("oh-my-zsh not installed at #{install_path}") unless @system.dir_exist?(install_path)
    @errors.empty?
  end

  def run
    output, status = execute("git clone --depth=1 #{OH_MY_ZSH_URL} #{install_path}")
    add_error("Failed to clone oh-my-zsh: #{output}") unless status == 0
  end

  private

  def install_path
    File.join(@home, INSTALL_DIR)
  end
end
