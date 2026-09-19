# areweproxyyet.github.io

## Site

# This repository contains a small GitHub Pages site under the `docs/` folder.

The site is built with Jekyll from the `docs/` folder and served by GitHub Pages (deploy from the `main` branch), using the built-in Pages build.

How the site data is organized
- Project entries are stored in `docs/_data/projects.yml`. The Jekyll template in `docs/index.html` reads `site.data.projects.projects` and renders each project card at build time.
- Dependency badges come from `docs/_data/deps.yml`. The script `scripts/project_deps.rb` generates that file. It fetches `Cargo.lock` from each program repository and reads the direct dependencies of the workspace members. The file is committed to the repository so the built-in Pages build ships the badges, and the `refresh-deps` workflow regenerates it and commits the result on every push to `main` and on a weekly schedule, so nobody updates it by hand.
- Three badge groups exist. The foundation badge shows one of pingora, rama, hyper, or axum, in that priority. The TLS badges show each of rustls, openssl, boring, and native-tls that the project uses. The QUIC badges show each of quinn and s2n-quic that the project uses.
- Libraries get no dependency badges.
- An optional `deps_repo` field on a project entry names a different GitHub repository for the dependency lookup only.

Adding or updating projects
- Edit `docs/_data/projects.yml` and add a new item under `projects:` with fields:
	- `name`: short display name
	- `repo`: GitHub URL (e.g. `https://github.com/owner/repo`)
	- `desc`: a one-line description
- Commit and push the change to `main` (or open a PR). The built-in Pages build deploys the site, and the `refresh-deps` workflow updates the badges.

Building and previewing locally (Bundler only)
- Requirements: Ruby and Bundler. This repository provides a `docs/Gemfile` to pin the Jekyll version.

- Install and preview with Bundler (fish example):

```fish
cd docs
gem install bundler       # only if bundler is not installed yet
bundle install
bundle exec jekyll serve --host 127.0.0.1 --port 4000 --livereload
```

This runs a local Jekyll server and writes the generated site into `../_site` while watching for changes.

To show the dependency badges in a local preview, generate the data file first from the repository root:

```fish
ruby scripts/project_deps.rb
```

The `scripts/preview.sh` helper runs that step for you.

Tests
- Run the script tests with `ruby test/project_deps_test.rb`.

Notes
- Only edit `docs/_data/projects.yml` to change the list; other copies (for example `docs/data/projects.yml`) are not used by the Jekyll template and won't affect the site.
- If you add a project (or change a `deps_repo` or `foundation`), run `ruby scripts/project_deps.rb` from the repository root and commit the updated `docs/_data/deps.yml` so the badges show immediately. Otherwise the `refresh-deps` workflow does it on the next run.

Deployment notes
- The site is deployed by GitHub's built-in Pages build from the `main` branch, so the dependency data must live in the repository (see `docs/_data/deps.yml`).
- The `refresh-deps` workflow commits the regenerated `docs/_data/deps.yml` back to `main` using the automatically-provided `GITHUB_TOKEN`. If repository branch protection or organization policies prevent `GITHUB_TOKEN` from pushing to `main`, create a personal access token (PAT) with `repo` scope and add it to the repository secrets as `PAGES_DEPLOY_TOKEN`.

	To create the secret:

	1. Go to your repository on GitHub → Settings → Secrets and variables → Actions → New repository secret.
 2. Name it `PAGES_DEPLOY_TOKEN` and paste a PAT that has `repo` scope.

	The workflow will prefer `PAGES_DEPLOY_TOKEN` if present and fall back to `GITHUB_TOKEN` otherwise.
