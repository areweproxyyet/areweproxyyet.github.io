#!/usr/bin/env bash
set -euo pipefail

# Preview the Jekyll site locally. This script:
# - cd into docs/
# - installs bundle if Gemfile exists (requires `gem` and `bundle`)
# - runs `jekyll serve` to preview at http://127.0.0.1:4000

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR/docs"

echo "Previewing Jekyll site from: $(pwd)"

if [ -f Gemfile ]; then
  if command -v bundle >/dev/null 2>&1; then
    echo "Installing bundle dependencies..."
    bundle install
    echo "Starting: bundle exec jekyll serve --source . --destination ../_site --livereload --host 127.0.0.1 --port 4000"
    bundle exec jekyll serve --source . --destination ../_site --livereload --host 127.0.0.1 --port 4000
  else
    echo "Bundler not found. Install bundler with: gem install bundler" >&2
    exit 1
  fi
else
  if command -v jekyll >/dev/null 2>&1; then
    echo "Starting: jekyll serve --source . --destination ../_site --livereload --host 127.0.0.1 --port 4000"
    jekyll serve --source . --destination ../_site --livereload --host 127.0.0.1 --port 4000
  else
    echo "Jekyll not found. Install Jekyll (gem install jekyll) or add a Gemfile." >&2
    exit 1
  fi
fi
