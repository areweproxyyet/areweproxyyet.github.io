#!/usr/bin/env ruby
# Reads docs/_data/projects.yml, fetches Cargo.lock from each GitHub repository,
# and writes the dependency badges of each program to docs/_data/deps.yml.
# Only direct dependencies of the workspace members count, so a crate that
# arrives through another dependency does not produce a badge.
# A project can name a different repository for this lookup with deps_repo,
# for example when the proxy code lives apart from the main repository.
require 'net/http'
require 'uri'
require 'yaml'

module ProjectDeps
  PROJECTS_PATH = 'docs/_data/projects.yml'.freeze
  OUTPUT_PATH = 'docs/_data/deps.yml'.freeze
  GITHUB_REPO = %r{\Ahttps://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?\z}.freeze

  # Foundation badges are exclusive. The first entry with a direct hit wins.
  # The crate list of each entry doubles as the lookup order for the version.
  FOUNDATIONS = [
    ['pingora', %w[pingora-core pingora pingora-proxy]],
    ['rama', %w[rama]],
    ['hyper', %w[hyper]],
    ['axum', %w[axum]]
  ].freeze
  TLS = %w[rustls openssl boring native-tls].freeze
  QUIC = %w[quinn s2n-quic].freeze

  module_function

  def packages(text)
    pkgs = []
    cur = nil
    in_deps = false
    text.each_line do |raw|
      line = raw.strip
      if line == '[[package]]'
        cur = { 'deps' => [] }
        pkgs << cur
        in_deps = false
      elsif line.start_with?('[[', '[')
        cur = nil
        in_deps = false
      elsif cur.nil?
        next
      elsif in_deps
        in_deps = false if line == ']'
        cur['deps'] << line[/"([^"]+)"/, 1] if line.start_with?('"')
      elsif (m = line.match(/\Aname = "([^"]+)"\z/))
        cur['name'] = m[1]
      elsif (m = line.match(/\Aversion = "([^"]+)"\z/))
        cur['version'] = m[1]
      elsif line.start_with?('source =')
        cur['source'] = true
      elsif line.start_with?('dependencies = [')
        if line.end_with?(']')
          cur['deps'].concat(line.scan(/"([^"]+)"/).flatten)
        else
          in_deps = true
        end
      end
    end
    pkgs
  end

  def direct_dependencies(text)
    pkgs = packages(text)
    versions = pkgs.each_with_object({}) { |p, h| h[p['name']] ||= p['version'] }
    members = pkgs.reject { |p| p['source'] }
    members.flat_map { |p| p['deps'] }.each_with_object({}) do |entry, direct|
      name, version = entry.split(' ', 3)
      direct[name] = version || versions[name]
    end
  end

  def badges(direct, foundation_override = nil)
    out = []
    foundation = foundation_badge(direct, foundation_override)
    out << foundation if foundation
    TLS.each { |c| out << badge('tls', c, direct[c]) if direct[c] }
    QUIC.each { |c| out << badge('quic', c, direct[c]) if direct[c] }
    out
  end

  def foundation_badge(direct, override)
    return badge('foundation', override, nil) if override
    FOUNDATIONS.each do |label, crates|
      next unless crates.any? { |c| direct.key?(c) }
      version = crates.map { |c| direct[c] }.compact.first
      return badge('foundation', label, version)
    end
    nil
  end

  def badge(group, crate, version)
    { 'group' => group, 'crate' => crate, 'version' => version }
  end

  def lock_url(repo)
    m = repo.to_s.match(GITHUB_REPO)
    return nil unless m
    "https://raw.githubusercontent.com/#{m[1]}/#{m[2]}/HEAD/Cargo.lock"
  end

  def fetch(url)
    res = Net::HTTP.get_response(URI.parse(url))
    res.is_a?(Net::HTTPSuccess) ? res.body : nil
  rescue StandardError => e
    warn "fetch failed for #{url}: #{e.message}"
    nil
  end

  def collect(projects, fetcher = method(:fetch))
    projects.each_with_object({}) do |p, result|
      next if p['kind'] == 'library'
      url = lock_url(p['deps_repo'] || p['repo'])
      next unless url
      lock = fetcher.call(url)
      next unless lock
      list = badges(direct_dependencies(lock), p['foundation'])
      result[p['repo']] = list unless list.empty?
    end
  end

  def run
    projects = YAML.load_file(PROJECTS_PATH).fetch('projects')
    result = collect(projects)
    File.write(OUTPUT_PATH, result.to_yaml)
    puts "wrote #{OUTPUT_PATH} with badges for #{result.size} projects"
  end
end

ProjectDeps.run if $PROGRAM_NAME == __FILE__
