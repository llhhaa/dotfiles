#!/usr/bin/env ruby

require_relative "dotfiles/loader"

Dotfiles::Loader.load!

class Dotfiles
  @log_file = nil

  def self.log_file=(path)
    @log_file = path
  end

  def self.log_file
    @log_file
  end

  def self.debug(message)
    timestamp = Time.now.strftime("%H:%M:%S.%3N")
    formatted = "[#{timestamp}] #{message}"

    if @log_file
      File.open(@log_file, "a") { |f| f.puts(formatted) }
    end

    puts formatted if ENV["DEBUG"] == "true"
  end

  def self.debug_benchmark(label, &block)
    start = Time.now
    result = block.call
    elapsed = ((Time.now - start) * 1000).round(2)
    debug "#{label} took #{elapsed}ms"
    result
  end

  def self.command_exists?(command)
    system("command -v #{command} >/dev/null 2>&1")
  end

  def self.determine_dotfiles_dir
    env_dir = ENV["DOTFILES_DIR"].to_s.strip
    if !env_dir.empty?
      expanded = File.expand_path(env_dir)
      return expanded if Dir.exist?(expanded)
    end

    cwd = Dir.pwd
    return cwd if File.exist?(File.join(cwd, "config", "config.yml"))

    File.expand_path("~/.dotfiles")
  end
end
