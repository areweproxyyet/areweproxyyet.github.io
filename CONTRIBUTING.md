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

CI validation
- The repository includes a GitHub Action that validates `docs/_data/projects.yml` on pull requests and pushes. The action checks that the file parses as YAML and that each project entry contains non-empty `name`, `repo`, and `desc` fields.

Pull request process
- Open a pull request with your changes to `docs/_data/projects.yml`.
- CI will run the validation job; if it passes, a maintainer can merge your contribution.

Questions
- If you're unsure about a project entry, open an issue first and we can discuss where/how it should appear.
