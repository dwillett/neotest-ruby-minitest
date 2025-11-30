# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

neotest-ruby-minitest is a Neovim plugin that integrates Ruby's Minitest framework with Neotest. It provides test discovery, execution, and result parsing for Minitest files in Neovim.

## Development Commands

```bash
make deps      # Clone required dependencies (plenary, neotest, nvim-nio, nvim-treesitter)
make test      # Run all tests using nvim in headless mode
make lint      # Run luacheck linting
make clean     # Remove cloned dependencies
```

Always run `make test && make lint` before submitting changes.

## Architecture

The plugin implements the Neotest adapter interface with these key components:

### Lua Modules (`lua/neotest-ruby-minitest/`)

- **init.lua** - Entry point and adapter factory. Exposes the 6 Neotest interface functions: `root()`, `is_test_file()`, `filter_dir()`, `discover_positions()`, `build_spec()`, `results()`
- **positions.lua** - Test position discovery using Treesitter. Uses three separate queries (plain, bare, rails) to handle different Minitest patterns, then returns the query with the most discovered tests
- **command.lua** - Builds Ruby command to execute tests. Injects the Ruby plugin via RUBYOPT env var and generates unique JSON output paths
- **results.lua** - Parses JSON output from test runs into Neotest result format
- **root.lua** - Project root detection (Gemfile, .ruby-version, .git, test/test_helper.rb)
- **util.lua** - Utilities for test file detection (`*_test.rb`, `test_*.rb`, `*_spec.rb`) and UUID generation
- **config.lua** - Configuration management with defaults (`command = "ruby -Itest"`, `env = {}`)

### Ruby Component (`ruby/json_tap.rb`)

Reporter-agnostic result collector that hooks into Minitest's core hooks via prepend. Activated via ENV variables (`MINITEST_JSON=1` or `MINITEST_JSON_FILE`). Outputs JSON with test metadata and failure details.

### Data Flow

1. Neotest calls `discover_positions()` which uses Treesitter to find test classes/methods
2. `build_spec()` constructs the Ruby command with RUBYOPT injection pointing to json_tap.rb
3. Minitest runs with json_tap.rb collecting results to a unique JSON file
4. `results()` parses the JSON and returns structured results to Neotest

## Test Discovery Strategy

Three Treesitter queries handle different Minitest patterns:
- **Plain Query**: Standard `Minitest::Test` subclass with `test_*` methods
- **Bare Query**: Flexible superclass resolution (local or namespaced)
- **Rails Query**: Rails TestCase variants (SystemTestCase, IntegrationTest, etc.) + `test "name" do` blocks

The query returning the most tests is used.

## Testing

Tests use Plenary/Busted and run in headless Neovim. Test files are in `tests/*_spec.lua` with example Minitest files in `tests/examples/` and JSON samples in `tests/json/`.
