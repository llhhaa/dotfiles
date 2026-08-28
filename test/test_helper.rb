require "minitest/autorun"
require "stringio"
require "tmpdir"
require "fileutils"
require "yaml"
require "delegate"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "dotfiles"

# Wraps a real SystemAdapter so filesystem ops work normally;
# overrides #execute to record and stub shell calls.
class FakeSystem < SimpleDelegator
  attr_reader :commands

  def initialize(real = Dotfiles::SystemAdapter.new)
    super(real)
    @commands = []
    @stubs = []
  end

  def stub(pattern, output: "", status: 0)
    @stubs << [pattern, [output, status]]
    self
  end

  def execute(command, quiet: true)
    @commands << command
    match = @stubs.find { |pat, _| pat === command }
    match ? match[1] : ["", 0]
  end
end

class Minitest::Test
  def recording_formatter(results, system_calls:, exit_codes: [], gum_available: true)
    Dotfiles::OutputFormatter.new(
      results,
      popen_call: ->(_cmd, _mode, &block) { block.call(StringIO.new) },
      system_call: ->(*args) { system_calls << args; true },
      exit_call: ->(code) { exit_codes << code },
      gum_available: ->(_cmd) { gum_available }
    )
  end
end
