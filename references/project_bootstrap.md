# Bootstrap Guide: Elixir/Phoenix/Ash Projects

A generic guideline for setting up Elixir projects with Phoenix, Ash Framework,
and modern development tooling.

## Overview

This guide covers:

1. Reproducible development environment with Nix
2. Project bootstrapping with Igniter
3. Database configuration
4. Code quality tooling (formatting, linting, testing)
5. Pre-commit and CI workflows
6. MCP server integration for AI-assisted development

---

## Phase 1: Development Environment

### Nix Flake

Create `flake.nix` for reproducible development dependencies:

```nix
{
  description = "Project description";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Elixir/Erlang
            beamMinimal28Packages.elixir_1_19
            beamMinimal28Packages.erlang
            beamMinimal28Packages.rebar3

            # Database (choose one)
            sqlite          # For SQLite
            # postgresql_16 # For PostgreSQL

            # Node.js (for Phoenix assets)
            nodejs_22

            # Formatting tools
            nixfmt-rfc-style
            nodePackages.prettier
            shfmt
          ];

          shellHook = ''
            export MIX_HOME="$PWD/.nix-mix"
            export HEX_HOME="$PWD/.nix-hex"
            export PATH="$MIX_HOME/bin:$HEX_HOME/bin:$PATH"
            export LANG="en_US.UTF-8"
            export ERL_AFLAGS="-kernel shell_history enabled"

            mix local.hex --force --if-missing
            mix local.rebar --force --if-missing
          '';
        };
      }
    );
}
```

### direnv

Create `.envrc`:

```bash
use flake
dotenv_if_exists
```

Then run:

```bash
direnv allow
```

### .gitignore additions

```gitignore
# Nix
.nix-mix/
.nix-hex/
.direnv/
result

# Elixir/Phoenix
/_build/
/deps/
/priv/static/assets/
erl_crash.dump
*.ez
*.beam
.elixir_ls/

# Database
*.db
*.db-*

# Environment
.env
!.env.example
```

---

## Phase 2: Project Bootstrap

### Using Igniter

Bootstrap a new Phoenix project with Ash:

```bash
# For SQLite
mix igniter.new project_name \
  --install ash,ash_sqlite,ash_phoenix \
  --with phx.new

# For PostgreSQL
mix igniter.new project_name \
  --install ash,ash_postgres,ash_phoenix \
  --with phx.new \
  --extend postgres
```

### Additional packages

```bash
mix igniter.install reactor      # Workflow orchestration
mix igniter.install live_svelte  # Svelte in LiveView (optional)
mix igniter.install oban         # Background jobs (optional)
```

---

## Phase 3: Database Configuration

### SQLite (config/dev.exs)

```elixir
config :my_app, MyApp.Repo,
  database: Path.expand("../my_app_dev.db", __DIR__),
  pool_size: 5,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true
```

### SQLite (config/test.exs)

```elixir
config :my_app, MyApp.Repo,
  database: Path.expand("../my_app_test#{System.get_env("MIX_TEST_PARTITION")}.db", __DIR__),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2
```

### PostgreSQL (config/dev.exs)

```elixir
config :my_app, MyApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "my_app_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### Runtime configuration

Remove or move port configuration from `config/runtime.exs` to avoid overriding
dev settings:

```elixir
# Only set PORT in production
if config_env() == :prod do
  config :my_app, MyAppWeb.Endpoint,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ]
end
```

---

## Phase 4: Mix Aliases

Add to `mix.exs`:

```elixir
def cli do
  [
    preferred_envs: [precommit: :test, ci: :test]
  ]
end

defp aliases do
  [
    setup: ["deps.get", "ash.setup", "assets.setup", "assets.build"],
    "db.setup": ["ash.setup"],
    "db.reset": ["ash_sqlite.drop", "ash.setup"],  # or ash_postgres
    "db.migrate": ["ash_sqlite.migrate"],          # or ash_postgres
    test: ["ash.setup --quiet", "test"],

    # Pre-commit: format files, compile strictly, test
    precommit: [
      "format",
      "deps.unlock --check-unused",
      "compile --warnings-as-errors",
      "test"
    ],

    # CI: check format (fail if not formatted), compile strictly, test
    ci: [
      "format --check-formatted",
      "deps.unlock --check-unused",
      "compile --warnings-as-errors",
      "test"
    ]
  ]
end
```

---

## Phase 5: Pre-commit and CI Scripts

### scripts/pre-commit.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Formatting non-Elixir files..."

# Format Nix files
if command -v nixfmt &>/dev/null; then
  echo "    Formatting Nix files..."
  find . -name "*.nix" -not -path "./.nix-*" -not -path "./.direnv/*" \
    -exec nixfmt {} + 2>/dev/null || true
fi

# Format YAML/JSON/Markdown files
if command -v prettier &>/dev/null; then
  echo "    Formatting YAML/JSON/Markdown files..."
  prettier --write --log-level warn "**/*.{yaml,yml,json,md}" \
    --ignore-path .gitignore 2>&1 || true
fi

# Format shell scripts
if command -v shfmt &>/dev/null; then
  echo "    Formatting shell scripts..."
  shfmt -w -i 2 -ci scripts/*.sh 2>/dev/null || true
fi

echo "==> Running Elixir pre-commit checks..."
mix precommit

echo "==> Pre-commit checks passed!"
```

### scripts/ci.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Checking non-Elixir file formatting..."

EXIT_CODE=0

# Check Nix files
if command -v nixfmt &>/dev/null; then
  echo "    Checking Nix files..."
  NIX_FILES=$(find . -name "*.nix" -not -path "./.nix-*" -not -path "./.direnv/*" 2>/dev/null || true)
  if [ -n "$NIX_FILES" ]; then
    if ! echo "$NIX_FILES" | xargs nixfmt --check 2>/dev/null; then
      echo "    ERROR: Nix files are not formatted. Run ./scripts/pre-commit.sh"
      EXIT_CODE=1
    fi
  fi
fi

# Check YAML/JSON/Markdown files
if command -v prettier &>/dev/null; then
  echo "    Checking YAML/JSON/Markdown files..."
  if ! prettier --check "**/*.{yaml,yml,json,md}" --ignore-path .gitignore 2>&1; then
    echo "    ERROR: Files are not formatted. Run ./scripts/pre-commit.sh"
    EXIT_CODE=1
  fi
fi

# Check shell scripts
if command -v shfmt &>/dev/null; then
  echo "    Checking shell scripts..."
  if ! shfmt -d -i 2 -ci scripts/*.sh 2>/dev/null; then
    echo "    ERROR: Shell scripts are not formatted. Run ./scripts/pre-commit.sh"
    EXIT_CODE=1
  fi
fi

if [ $EXIT_CODE -ne 0 ]; then
  echo "==> Non-Elixir formatting check failed!"
  exit $EXIT_CODE
fi

echo "==> Running Elixir CI checks..."
mix ci

echo "==> CI checks passed!"
```

Make executable:

```bash
chmod +x scripts/pre-commit.sh scripts/ci.sh
```

---

## Phase 6: Prettier Configuration

### .prettierrc

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "overrides": [
    {
      "files": "*.md",
      "options": {
        "proseWrap": "always"
      }
    }
  ]
}
```

### .prettierignore

```
_build/
deps/
priv/static/assets/
node_modules/
.nix-mix/
.nix-hex/
.direnv/
result
assets/vendor/
```

---

## Phase 7: TideWave MCP Integration (Optional)

For AI-assisted development with Claude Code.

### Add to mix.exs deps

```elixir
{:tidewave, "~> 0.5", only: :dev}
```

### Add to endpoint.ex (after use Phoenix.Endpoint)

```elixir
if Code.ensure_loaded?(Tidewave) do
  plug Tidewave
end
```

### Create .mcp.json

```json
{
  "mcpServers": {
    "tidewave": {
      "type": "http",
      "url": "http://localhost:4000/tidewave/mcp"
    }
  }
}
```

---

## Phase 8: Elixir Version Compatibility

### Regex flags (Elixir 1.18+)

The `E` flag is deprecated. Remove it from regex patterns in config files:

```elixir
# Before (deprecated)
~r"lib/my_app_web/.*\.(ex|heex)$"E

# After
~r"lib/my_app_web/.*\.(ex|heex)$"
```

### assets/package.json

If using vendor JavaScript files with CommonJS, create `assets/package.json`:

```json
{
  "name": "my-app-assets",
  "version": "1.0.0",
  "private": true,
  "type": "commonjs"
}
```

---

## Quick Start Checklist

1. [ ] Create `flake.nix` with Elixir, database, and formatting tools
2. [ ] Create `.envrc` and run `direnv allow`
3. [ ] Update `.gitignore` with Nix and Elixir patterns
4. [ ] Bootstrap project with `mix igniter.new`
5. [ ] Configure database in `config/dev.exs` and `config/test.exs`
6. [ ] Fix `config/runtime.exs` port configuration
7. [ ] Add `precommit` and `ci` aliases to `mix.exs`
8. [ ] Create `scripts/pre-commit.sh` and `scripts/ci.sh`
9. [ ] Create `.prettierrc` and `.prettierignore`
10. [ ] (Optional) Add TideWave for MCP integration
11. [ ] Run `mix setup` to initialize everything
12. [ ] Run `./scripts/pre-commit.sh` to verify setup

---

## Usage

```bash
# Development
mix phx.server

# Pre-commit (formats and tests)
./scripts/pre-commit.sh

# CI (checks formatting and tests)
./scripts/ci.sh

# Database operations
mix db.setup
mix db.reset
mix db.migrate
```
