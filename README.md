# areweproxyyet.github.io

## Site

# This repository contains a small GitHub Pages site under the `docs/` folder.

The site is built with Jekyll from the `docs/` folder and the GitHub Actions workflow in `.github/workflows/pages.yml` builds the site and deploys the generated static output.

How the site data is organized
- Project entries are stored in `docs/_data/projects.yml`. The Jekyll template in `docs/index.html` reads `site.data.projects.projects` and renders each project card at build time.

Adding or updating projects
- Edit `docs/_data/projects.yml` and add a new item under `projects:` with fields:
	- `name`: short display name
	- `repo`: GitHub URL (e.g. `https://github.com/owner/repo`)
	- `desc`: a one-line description
- Commit and push the change to `main` (or open a PR). The GitHub Actions workflow will build and deploy the site.

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

Notes
- Only edit `docs/_data/projects.yml` to change the list; other copies (for example `docs/data/projects.yml`) are not used by the Jekyll template and won't affect the site.
- The CI workflow builds the site using Bundler and deploys the generated `_site`.

Deployment notes
- The workflow attempts to publish using the automatically-provided `GITHUB_TOKEN`. If repository branch protection or organization policies prevent `GITHUB_TOKEN` from pushing to the `gh-pages` branch, create a personal access token (PAT) with `repo` scope and add it to the repository secrets as `PAGES_DEPLOY_TOKEN`.

	To create the secret:

	1. Go to your repository on GitHub → Settings → Secrets and variables → Actions → New repository secret.
 2. Name it `PAGES_DEPLOY_TOKEN` and paste a PAT that has `repo` scope.

	The workflow will prefer `PAGES_DEPLOY_TOKEN` if present and fall back to `GITHUB_TOKEN` otherwise.
