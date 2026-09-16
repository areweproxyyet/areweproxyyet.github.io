#!/usr/bin/env ruby
# Reads docs/_data/projects.yml, fetches Cargo.lock from each GitHub repository,
# and writes the resolved pingora-core version of each project to
# docs/_data/pingora.yml. The Jekyll template renders that file as a badge.
require 'net/http'
require 'uri'
require 'yaml'

module PingoraVersions
  PROJECTS_PATH = 'docs/_data/projects.yml'.freeze
  OUTPUT_PATH = 'docs/_data/pingora.yml'.freeze
  CRATE = 'pingora-core'.freeze
  GITHUB_REPO = %r{\Ahttps://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?\z}.freeze

  module_function

  def version_from_lock(text)
    current_name = nil
    current_version = nil
    text.each_line do |line|
      line = line.strip
      if line == '[[package]]'
        return current_version if current_name == CRATE && current_version
        current_name = nil
        current_version = nil
      elsif (m = line.match(/\Aname = "([^"]+)"\z/))
        current_name = m[1]
      elsif (m = line.match(/\Aversion = "([^"]+)"\z/))
        current_version = m[1]
      end
    end
    current_name == CRATE ? current_version : nil
  end

  def lock_url(repo)
    m = repo.to_s.match(GITHUB_REPO)
    return nil unless m
    "https://raw.githubusercontent.com/#{m[1]}/#{m[2]}/HEAD/Cargo.lock"
  end

  def fetch(url)
    uri = URI.parse(url)
    res = Net::HTTP.get_response(uri)
    res.is_a?(Net::HTTPSuccess) ? res.body : nil
  rescue StandardError => e
    warn "fetch failed for #{url}: #{e.message}"
    nil
  end

  def collect(projects, fetcher = method(:fetch))
    projects.each_with_object({}) do |p, result|
      url = lock_url(p['repo'])
      next unless url
      lock = fetcher.call(url)
      next unless lock
      version = version_from_lock(lock)
      next unless version
      result[p['repo']] = { 'pingora' => version }
    end
  end

  def run
    projects = YAML.load_file(PROJECTS_PATH).fetch('projects')
    result = collect(projects)
    File.write(OUTPUT_PATH, result.to_yaml)
    puts "wrote #{OUTPUT_PATH} with #{result.size} pingora versions"
  end
end

PingoraVersions.run if $PROGRAM_NAME == __FILE__
