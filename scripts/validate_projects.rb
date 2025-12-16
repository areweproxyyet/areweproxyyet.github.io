#!/usr/bin/env ruby
require 'yaml'
require 'uri'

def valid_url?(str)
  return false if str.to_s.strip == ''
  uri = URI.parse(str)
  %w[http https].include?(uri.scheme)
rescue URI::InvalidURIError
  false
end

path = 'docs/_data/projects.yml'
unless File.exist?(path)
  STDERR.puts "File not found: #{path}"
  exit 1
end

begin
  data = YAML.load_file(path)
rescue => e
  STDERR.puts "YAML parse error: #{e.message}"
  exit 1
end

unless data.is_a?(Hash) && data['projects'].is_a?(Array)
  STDERR.puts 'projects key missing or not an array'
  exit 1
end

errors = []
data['projects'].each_with_index do |p, i|
  unless p.is_a?(Hash)
    errors << "project[#{i}] is not a map"
    next
  end
  %w[name repo desc].each do |k|
    if !p.key?(k) || p[k].to_s.strip == ''
      errors << "project[#{i}] missing or empty #{k}"
    end
  end

  # kind must be present and one of allowed values
  allowed_kinds = %w[program library]
  if !p.key?('kind') || p['kind'].to_s.strip == ''
    errors << "project[#{i}] missing or empty kind"
  elsif !allowed_kinds.include?(p['kind'].to_s)
    errors << "project[#{i}] has invalid kind: #{p['kind']} (must be one of #{allowed_kinds.join(', ')})"
  end

  if p.key?('site') && !valid_url?(p['site'])
    errors << "project[#{i}] has invalid site URL: #{p['site']}"
  end

  if p.key?('icon') && !valid_url?(p['icon'])
    errors << "project[#{i}] has invalid icon URL: #{p['icon']}"
  end
  if p.key?('license') && p['license'].to_s.strip == ''
    errors << "project[#{i}] has an empty license field"
  end
end

if errors.any?
  STDERR.puts errors.join("\n")
  exit 1
end

puts 'projects.yml validated successfully'
