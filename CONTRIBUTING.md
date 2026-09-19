Contributing
============

Thank you for wanting to contribute!

How to add a project
- Edit the canonical data file: `docs/_data/projects.yml`.
- Add a new entry under `projects:` with the following keys:
  - `name`: short display name (string)
  - `repo`: full GitHub repo URL (https://github.com/owner/repo)
  - `desc`: one-line description

Example entry:

```yaml
projects:
  - name: example
    repo: https://github.com/owner/example
    desc: A short description of the project.
```

Local preview
- Run a local Jekyll server with:

```fish
cd docs
gem install bundler   # if not already installed
bundle install
bundle exec jekyll serve --host 127.0.0.1 --port 4000 --livereload
```

Dependency badges
- Programs get badges for their foundation crate (pingora, rama, hyper, or axum), their TLS crates, and their QUIC crates.
- The badges are automatic. The build reads the `Cargo.lock` file at the root of the GitHub repository and uses only direct dependencies.
- Do not add version fields for them to `projects.yml`.
- If the proxy code lives in a different repository than `repo`, add `deps_repo` with that GitHub URL. The badges then read the `Cargo.lock` file from `deps_repo`, and everything else on the card still uses `repo`.
- If the detected foundation is wrong, for example because the project has its own HTTP stack, add `foundation: custom` to the entry. An optional `note` field with one sentence appears on the card if you want to explain the situation.

CI validation
- The repository includes a GitHub Action that validates `docs/_data/projects.yml` on pull requests and pushes. The action checks that the file parses as YAML and that each project entry contains non-empty `name`, `repo`, and `desc` fields.

Pull request process
- Open a pull request with your changes to `docs/_data/projects.yml`.
- CI will run the validation job; if it passes, a maintainer can merge your contribution.

Questions
- If you're unsure about a project entry, open an issue first and we can discuss where/how it should appear.
