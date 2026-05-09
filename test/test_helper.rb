require "minitest/autorun"
require "stringio"
require "tmpdir"
require "fileutils"
require "yaml"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "dotfiles"

class Minitest::Test
  def recording_formatter(results, system_calls:, exit_codes: [])
    Dotfiles::OutputFormatter.new(
      results,
      popen_call: ->(_cmd, _mode, &block) { block.call(StringIO.new) },
      system_call: ->(*args) { system_calls << args; true },
      exit_call: ->(code) { exit_codes << code }
    )
  end
end
