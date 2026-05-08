require "yaml"

class Dotfiles
  class Config
    attr_reader :dotfiles_dir
    attr_writer :config

    def initialize(dotfiles_dir, system: SystemAdapter.new)
      @dotfiles_dir = dotfiles_dir
      @config_dir = File.join(dotfiles_dir, "config")
      @system = system
    end

    def config
      @config ||= load_config
    end

    def dotfiles_repo
      config["dotfiles_repo"] || "https://github.com/llhhaa/dotfiles.git"
    end

    def home
      config["home"] || ENV["HOME"]
    end

    def [](key)
      config[key]
    end

    def fetch(key, default = nil)
      config.fetch(key, default)
    end

    def brew_casks
      config.fetch("brew", {}).fetch("casks", [])
    end

    def applications
      config.fetch("applications", [])
    end

    private

    def load_config
      config_path = File.join(@config_dir, "config.yml")
      content = @system.read_file(config_path)
      YAML.safe_load(content, permitted_classes: [Symbol])
    rescue Errno::ENOENT
      {}
    end
  end
end
