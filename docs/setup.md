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
4. Loads `lib/dotfiles.rb`, which auto-requires every step under `lib/dotfiles/steps/`.
5. `Dotfiles::Runner` topologically sorts steps by their `depends_on` declarations, runs each one in order (skipping any whose `complete?` already returns true, or whose `macos_only` / `debian_only` gate doesn't match the host), then renders a results table via `gum`.

The runner is designed to be re-runnable — `complete?` is the contract that lets a step be skipped on subsequent runs.

## Layout

| Path | Purpose |
| --- | --- |
| `bin/dotf` | CLI entry point (`run`, `help`). Sets up logging, calls `bootstrap`, then shells into the Ruby runner. |
| `bin/bootstrap` | Shell prerequisites — Homebrew, mise, Ruby (≥ 3.x), gum. Idempotent; safe to re-run. |
| `config/config.yml` | Declarative inputs: `dotfiles_repo`, `master_hostname`, `standard_folders`, cross-platform `packages`, `debian_sources` / `debian_non_apt_packages` / `debian_snap_packages`, `brew.casks`, `applications`, `unmanaged_apps`, `animation_settings`, `screenshot_settings`, `login_items`, `config_directory_items`, `file_associations`. |
| `lib/dotfiles.rb` | Top-level entry. Triggers `Loader.load!`, owns the log file handle, exposes `Dotfiles.debug` / `debug_benchmark` / `command_exists?` / `determine_dotfiles_dir`. |
| `lib/dotfiles/loader.rb` | Adds `lib/dotfiles` to `$LOAD_PATH`, requires core classes, then globs and requires every file under `steps/`. |
| `lib/dotfiles/runner.rb` | Orchestrates execution: builds step params, runs steps serially in topo order, then collects per-step results in parallel threads and hands them to the output formatter. |
| `lib/dotfiles/step.rb` | Base class. Tracks subclasses via `inherited`, provides `depends_on`, `macos_only` / `debian_only`, `display_name`, `Step.all_steps` topological sort, and helpers (`execute`, `command_exists?`, `files_match?`, `defaults_read_equals?`, etc.). |
| `lib/dotfiles/step/defaultable.rb` | Mixin: read / write / verify macOS `defaults` from a list of `(domain, key, value)` triples sourced from `config.yml`. |
| `lib/dotfiles/step/defaults_configurable.rb` | Convenience mixin for steps that are purely a `defaults write`. Auto-applies `macos_only`, defines `run` / `complete?` / `update`, and lets the subclass declare `defaults_config_key` / `defaults_display_name`. |
| `lib/dotfiles/system_adapter.rb` | Thin wrapper around the shell (`Open3`), filesystem (`FileUtils`), and platform detection (`macos?`, `debian?`). Mockable in tests. |
| `lib/dotfiles/config.rb` | Loads `config/config.yml` once and exposes typed accessors (`dotfiles_repo`, `home`, `brew_casks`, `applications`, plus `[]` / `fetch`). |
| `lib/dotfiles/output_formatter.rb` | Renders the final results table, errors, warnings, and notices via `gum table` and `gum style`. Exits 1 if any step is incomplete. |
| `lib/dotfiles/steps/mac/` | One file per step. Currently `ConfigureScreenshotsStep` and `DisableAnimationsStep` — both `DefaultsConfigurable`. |
| `mise.toml` | Pins `gum` for mise users (the `gum` CLI is required by the output formatter). |
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
