# Automated Setup

A Ruby-based runner that idempotently sets up a development environment from a declarative config file. It targets macOS primarily, with some Debian-aware plumbing in `config.yml`.

## Quick start

```shell
bin/dotf run            # initial setup
DEBUG=true bin/dotf run # also stream debug output to the console
bin/dotf help
```

## How it works

`bin/dotf` is the entry point. On `run` it:

1. Opens a timestamped log file under `logs/` (always written; `DEBUG=true` additionally tees to stdout).
2. Invokes `bin/bootstrap` to install shell prerequisites — Homebrew (macOS only), mise, Ruby ≥ 3.x (via `rbenv` by default, or `mise` if `RUBY_VERSION_MANAGER=mise`), and `gum`.
3. Re-evaluates the Homebrew and mise environments so freshly-installed binaries are on `PATH`.
4. Loads `lib/dotfiles.rb`, which auto-requires every step under `lib/dotfiles/steps/`. Files are sorted by directory depth so foundational top-level steps (e.g. `SymlinkDotfilesStep`) load before nested platform-specific ones (e.g. `steps/mac/*`); within the same depth the order is alphabetical.
5. `Dotfiles::Runner` topologically sorts steps by their `depends_on` declarations (load order is the tiebreaker), runs each one in order (skipping any whose `complete?` already returns true, or whose `macos_only` / `debian_only` gate doesn't match the host), then renders a results table via `gum`.

The runner is designed to be re-runnable — `complete?` is the contract that lets a step be skipped on subsequent runs.

## Layout

| Path | Purpose |
| --- | --- |
| `bin/dotf` | CLI entry point (`run`, `help`). Sets up logging, calls `bootstrap`, then shells into the Ruby runner. |
| `bin/bootstrap` | Shell prerequisites — Homebrew, mise, Ruby (≥ 3.x), gum. Idempotent; safe to re-run. |
| `bin/test` | Minitest runner. Loads every `test/**/*_test.rb`; forwards Minitest flags like `--name <pattern>` and `--seed <n>`. |
| `config/config.yml` | Declarative inputs: `dotfiles_repo`, `master_hostname`, `standard_folders`, `symlinks`, cross-platform `packages`, `debian_sources` / `debian_non_apt_packages` / `debian_snap_packages`, `brew.casks`, `applications`, `unmanaged_apps`, `animation_settings`, `screenshot_settings`, `login_items`, `config_directory_items`, `file_associations`. |
| `lib/dotfiles.rb` | Top-level entry. Triggers `Loader.load!`, owns the log file handle, exposes `Dotfiles.debug` / `debug_benchmark` / `command_exists?` / `determine_dotfiles_dir`. |
| `lib/dotfiles/loader.rb` | Adds `lib/dotfiles` to `$LOAD_PATH`, requires core classes, then globs and requires every file under `steps/`. |
| `lib/dotfiles/runner.rb` | Orchestrates execution: builds step params, runs steps serially in topo order, then collects per-step results in parallel threads and hands them to the output formatter. |
| `lib/dotfiles/step.rb` | Base class. Tracks subclasses via `inherited`, provides `depends_on`, `macos_only` / `debian_only`, `display_name`, `Step.all_steps` topological sort, and helpers (`execute`, `command_exists?`, `files_match?`, `defaults_read_equals?`, etc.). |
| `lib/dotfiles/step/defaultable.rb` | Mixin: read / write / verify macOS `defaults` from a list of `(domain, key, value)` triples sourced from `config.yml`. |
| `lib/dotfiles/step/defaults_configurable.rb` | Convenience mixin for steps that are purely a `defaults write`. Auto-applies `macos_only`, defines `run` / `complete?` / `update`, and lets the subclass declare `defaults_config_key` / `defaults_display_name`. |
| `lib/dotfiles/system_adapter.rb` | Thin wrapper around the shell (`Open3`), filesystem (`FileUtils`), and platform detection (`macos?`, `debian?`). Mockable in tests. |
| `lib/dotfiles/config.rb` | Loads `config/config.yml` once and exposes typed accessors (`dotfiles_repo`, `home`, `brew_casks`, `applications`, plus `[]` / `fetch`). |
| `lib/dotfiles/output_formatter.rb` | Renders the final results table, errors, warnings, and notices via `gum table` and `gum style`. Exits 1 if any step is incomplete. |
| `lib/dotfiles/steps/symlink_dotfiles_step.rb` | Cross-platform. Reads the `symlinks` list from `config.yml` and links each entry into `$HOME`, backing up real files to `<dest>.bak` and replacing stale symlinks. |
| `lib/dotfiles/steps/mac/` | macOS-only steps. `ConfigureScreenshotsStep` and `DisableAnimationsStep` (both `DefaultsConfigurable`); `InstallBrewCasksStep` (diffs `config.brew_casks` against `brew list --cask` and installs the missing ones). |
| `mise.toml` | Pins `gum` for mise users (the `gum` CLI is required by the output formatter). |
| `test/` | Minitest suite. `test_helper.rb` holds shared boot + a `recording_formatter` helper. Mirrors `lib/` layout (`test/dotfiles/steps/foo_step_test.rb` ↔ `lib/dotfiles/steps/foo_step.rb`). |
| `logs/` | Timestamped per-run log files. Gitignored. |

## Adding a new step

Drop a file under `lib/dotfiles/steps/` whose class inherits `Dotfiles::Step`. The loader will pick it up automatically:

```ruby
class Dotfiles::Step::InstallMyToolStep < Dotfiles::Step
  macos_only  # optional; alternative: debian_only

  def self.depends_on
    [Dotfiles::Step::SomeOtherStep]  # optional ordering hint
  end

  def complete?
    super  # clears @errors
    command_exists?("mytool")
  end

  def run
    execute("brew install mytool")
  end
end
```

Contract:

- `complete?` is consulted both before running (to decide whether to skip) and after running (to verify success).
- `run` performs the side effect and may call `add_error` / `add_warning` / `add_notice` to surface messages in the final output.
- `depends_on` returns step classes — the runner topologically sorts them and aborts on cycles.
- For pure `defaults write` steps, `include Dotfiles::Step::DefaultsConfigurable`, set `defaults_config_key "..."` to point at a key in `config.yml`, and override `after_defaults_write` if you need to `killall` something. See `steps/mac/disable_animations_step.rb` for the canonical example.

## Configuration

`config/config.yml` is the single source of truth for what gets installed and configured. Adding a new macOS default is usually a two-step change: append the `(domain, key, value)` entry under the appropriate config key (e.g. `animation_settings`), and — if the key is new — wire it up in a step.

## Tests

```shell
bin/test                              # run everything
bin/test --name test_pattern_subset   # filter by name (Minitest --name)
bin/test --seed 12345                 # reproduce an ordering
```

Tests live under `test/` mirroring `lib/`. `test/test_helper.rb` provides:

- shared boot (`require "minitest/autorun"`, load-path setup, `Dotfiles` requires);
- `recording_formatter(results, system_calls:, exit_codes:)` — returns an `OutputFormatter` whose `popen_call` / `system_call` / `exit_call` are lambdas recording into the supplied arrays, so you can assert on rendered output without shelling out to `gum`;
- `FakeSystem` — a `SimpleDelegator` over a real `SystemAdapter` that overrides `execute` to record commands and serve canned `[output, status]` responses for regex/string patterns registered via `#stub`. Filesystem ops fall through to the real adapter, so tests can mix tempdir state with stubbed shell calls.
