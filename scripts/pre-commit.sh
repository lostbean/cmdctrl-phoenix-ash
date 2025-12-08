#!/usr/bin/env bash
set -euo pipefail

AUTO_STAGE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --stage)
      AUTO_STAGE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo "Running formatters..."

# Format Markdown files
echo "Formatting Markdown..."
find . -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -print0 |
  xargs -0 -r prettier --write --prose-wrap always 2>/dev/null || true

# Format JSON files
echo "Formatting JSON..."
find . -name "*.json" -not -path "./.git/*" -not -path "./node_modules/*" -print0 |
  xargs -0 -r prettier --write 2>/dev/null || true

# Format YAML files
echo "Formatting YAML..."
find . \( -name "*.yaml" -o -name "*.yml" \) -not -path "./.git/*" -not -path "./node_modules/*" -print0 |
  xargs -0 -r prettier --write 2>/dev/null || true

# Format Shell scripts
echo "Formatting Shell scripts..."
find . -name "*.sh" -not -path "./.git/*" -not -path "./node_modules/*" -print0 |
  xargs -0 -r shfmt -w -i 2 -ci 2>/dev/null || true

# Format TOML files
echo "Formatting TOML..."
find . -name "*.toml" -not -path "./.git/*" -not -path "./node_modules/*" -print0 |
  xargs -0 -r taplo format 2>/dev/null || true

# Format Nix files
echo "Formatting Nix..."
find . -name "*.nix" -not -path "./.git/*" -not -path "./node_modules/*" -print0 |
  xargs -0 -r nixfmt 2>/dev/null || true

# Format HTML/CSS/JS if present
echo "Formatting HTML/CSS/JS..."
find . \( -name "*.html" -o -name "*.css" -o -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \) \
  -not -path "./.git/*" -not -path "./node_modules/*" -not -path "./_build/*" -print0 |
  xargs -0 -r prettier --write 2>/dev/null || true

echo "Formatting complete!"

if [[ "$AUTO_STAGE" == "true" ]]; then
  git diff --name-only | while read -r file; do
    if [ -f "$file" ]; then
      git add "$file"
    fi
  done
fi
