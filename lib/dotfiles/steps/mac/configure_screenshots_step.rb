class Dotfiles::Step::ConfigureScreenshotsStep < Dotfiles::Step
  include Dotfiles::Step::DefaultsConfigurable

  defaults_config_key "screenshot_settings"
  defaults_display_name "Screenshot"

  private

  def after_defaults_write
    execute("killall SystemUIServer")
  end
end
