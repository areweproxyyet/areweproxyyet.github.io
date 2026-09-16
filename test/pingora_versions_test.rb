require 'minitest/autorun'
require_relative '../scripts/pingora_versions'

class PingoraVersionsTest < Minitest::Test
  def test_returns_the_pingora_core_version_from_a_lock_file
    # Arrange
    lock = <<~LOCK
      version = 4

      [[package]]
      name = "pingora"
      version = "0.9.0"
      source = "registry+https://github.com/rust-lang/crates.io-index"

      [[package]]
      name = "pingora-core"
      version = "0.9.0"
      source = "registry+https://github.com/rust-lang/crates.io-index"
      dependencies = [
       "tokio",
      ]

      [[package]]
      name = "tokio"
      version = "1.40.0"
    LOCK

    # Act
    version = PingoraVersions.version_from_lock(lock)

    # Assert
    assert_equal '0.9.0', version
  end

  def test_returns_nil_when_the_lock_file_has_no_pingora_core
    # Arrange
    lock = <<~LOCK
      [[package]]
      name = "hyper"
      version = "1.4.1"

      [[package]]
      name = "pingora-limits"
      version = "0.8.1"
    LOCK

    # Act
    version = PingoraVersions.version_from_lock(lock)

    # Assert
    assert_nil version
  end

  def test_ignores_a_version_line_that_belongs_to_another_package
    # Arrange
    lock = <<~LOCK
      [[package]]
      name = "pingora-core"
      source = "git+https://github.com/cloudflare/pingora?rev=abc123#abc123"
      version = "0.3.0"

      [[package]]
      name = "pingora-proxy"
      version = "0.4.0"
    LOCK

    # Act
    version = PingoraVersions.version_from_lock(lock)

    # Assert
    assert_equal '0.3.0', version
  end

  def test_builds_a_lock_url_from_a_github_repo_url
    # Arrange
    repo = 'https://github.com/vicanso/pingap'

    # Act
    url = PingoraVersions.lock_url(repo)

    # Assert
    assert_equal 'https://raw.githubusercontent.com/vicanso/pingap/HEAD/Cargo.lock', url
  end

  def test_lock_url_is_nil_for_a_non_github_repo
    # Arrange
    repo = 'https://codeberg.org/someone/proxy'

    # Act
    url = PingoraVersions.lock_url(repo)

    # Assert
    assert_nil url
  end

  def test_collects_versions_keyed_by_repo_and_skips_missing_data
    # Arrange
    projects = [
      { 'name' => 'pingap', 'repo' => 'https://github.com/vicanso/pingap' },
      { 'name' => 'rpxy', 'repo' => 'https://github.com/junkurihara/rust-rpxy' },
      { 'name' => 'gone', 'repo' => 'https://github.com/nobody/gone' }
    ]
    locks = {
      'https://raw.githubusercontent.com/vicanso/pingap/HEAD/Cargo.lock' => "[[package]]\nname = \"pingora-core\"\nversion = \"0.9.0\"\n",
      'https://raw.githubusercontent.com/junkurihara/rust-rpxy/HEAD/Cargo.lock' => "[[package]]\nname = \"hyper\"\nversion = \"1.0.0\"\n"
    }
    fetcher = ->(url) { locks[url] }

    # Act
    result = PingoraVersions.collect(projects, fetcher)

    # Assert
    assert_equal({ 'https://github.com/vicanso/pingap' => { 'pingora' => '0.9.0' } }, result)
  end
end
