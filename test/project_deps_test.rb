require 'minitest/autorun'
require_relative '../scripts/project_deps'

class ProjectDepsTest < Minitest::Test
  PINGAP_LOCK = <<~LOCK
    version = 4

    [[package]]
    name = "pingap"
    version = "0.12.0"
    dependencies = [
     "pingora",
     "rustls",
     "tokio",
    ]

    [[package]]
    name = "pingora"
    version = "0.9.0"
    source = "registry+https://github.com/rust-lang/crates.io-index"
    dependencies = [
     "pingora-core",
    ]

    [[package]]
    name = "pingora-core"
    version = "0.9.0"
    source = "registry+https://github.com/rust-lang/crates.io-index"
    dependencies = [
     "hyper",
     "tokio",
    ]

    [[package]]
    name = "hyper"
    version = "1.11.1"
    source = "registry+https://github.com/rust-lang/crates.io-index"

    [[package]]
    name = "rustls"
    version = "0.23.44"
    source = "registry+https://github.com/rust-lang/crates.io-index"

    [[package]]
    name = "tokio"
    version = "1.53.1"
    source = "registry+https://github.com/rust-lang/crates.io-index"
  LOCK

  def test_direct_dependencies_come_from_workspace_members_only
    # Arrange
    lock = PINGAP_LOCK

    # Act
    direct = ProjectDeps.direct_dependencies(lock)

    # Assert
    assert_equal %w[pingora rustls tokio], direct.keys.sort
    refute_includes direct.keys, 'hyper'
  end

  def test_direct_dependency_entry_with_a_version_keeps_that_version
    # Arrange
    lock = <<~LOCK
      [[package]]
      name = "app"
      version = "0.1.0"
      dependencies = [
       "hyper 0.14.32",
       "hyper 1.11.1",
      ]

      [[package]]
      name = "hyper"
      version = "0.14.32"
      source = "registry+https://github.com/rust-lang/crates.io-index"

      [[package]]
      name = "hyper"
      version = "1.11.1"
      source = "registry+https://github.com/rust-lang/crates.io-index"
    LOCK

    # Act
    direct = ProjectDeps.direct_dependencies(lock)

    # Assert
    assert_equal({ 'hyper' => '1.11.1' }, direct)
  end

  def test_single_line_dependency_list_is_parsed
    # Arrange
    lock = <<~LOCK
      [[package]]
      name = "app"
      version = "0.1.0"
      dependencies = ["hyper", "tokio"]

      [[package]]
      name = "hyper"
      version = "1.8.1"
      source = "registry+https://github.com/rust-lang/crates.io-index"

      [[package]]
      name = "tokio"
      version = "1.49.0"
      source = "registry+https://github.com/rust-lang/crates.io-index"
    LOCK

    # Act
    direct = ProjectDeps.direct_dependencies(lock)

    # Assert
    assert_equal({ 'hyper' => '1.8.1', 'tokio' => '1.49.0' }, direct)
  end

  def test_patch_unused_section_does_not_corrupt_the_last_package
    # Arrange
    lock = <<~LOCK
      [[package]]
      name = "app"
      version = "0.1.0"
      dependencies = [
       "hyper",
      ]

      [[package]]
      name = "hyper"
      version = "1.8.1"
      source = "registry+https://github.com/rust-lang/crates.io-index"

      [[patch.unused]]
      name = "pingora-cache"
      version = "0.3.0"
    LOCK

    # Act
    direct = ProjectDeps.direct_dependencies(lock)

    # Assert
    assert_equal({ 'hyper' => '1.8.1' }, direct)
  end

  def test_pingora_wins_the_foundation_badge_over_hyper
    # Arrange
    direct = { 'pingora-core' => '0.9.0', 'pingora-proxy' => '0.9.0', 'hyper' => '1.11.1', 'tokio' => '1.53.1' }

    # Act
    badges = ProjectDeps.badges(direct)

    # Assert
    assert_equal [{ 'group' => 'foundation', 'crate' => 'pingora', 'version' => '0.9.0' }], badges
  end

  def test_foundation_priority_is_pingora_rama_hyper_axum
    # Arrange
    cases = {
      { 'rama' => '0.5.0', 'hyper' => '1.0.0' } => 'rama',
      { 'hyper' => '1.0.0', 'axum' => '0.8.0' } => 'hyper',
      { 'axum' => '0.8.0', 'tokio' => '1.0.0' } => 'axum',
      { 'tokio' => '1.0.0' } => nil
    }

    # Act
    results = cases.keys.map { |direct| ProjectDeps.badges(direct).find { |b| b['group'] == 'foundation' }&.fetch('crate') }

    # Assert
    assert_equal cases.values, results
  end

  def test_tls_and_quic_badges_list_every_direct_hit_in_a_fixed_order
    # Arrange
    direct = { 'native-tls' => '0.2.15', 'quinn' => '0.11.12', 'openssl' => '0.10.78', 'rustls' => '0.23.37', 's2n-quic' => '1.88.0', 'hyper' => '1.11.1' }

    # Act
    badges = ProjectDeps.badges(direct)

    # Assert
    expected = [
      { 'group' => 'foundation', 'crate' => 'hyper', 'version' => '1.11.1' },
      { 'group' => 'tls', 'crate' => 'rustls', 'version' => '0.23.37' },
      { 'group' => 'tls', 'crate' => 'openssl', 'version' => '0.10.78' },
      { 'group' => 'tls', 'crate' => 'native-tls', 'version' => '0.2.15' },
      { 'group' => 'quic', 'crate' => 'quinn', 'version' => '0.11.12' },
      { 'group' => 'quic', 'crate' => 's2n-quic', 'version' => '1.88.0' }
    ]
    assert_equal expected, badges
  end

  def test_custom_foundation_override_replaces_the_detected_foundation
    # Arrange
    direct = { 'hyper' => '1.11.1', 'rustls' => '0.23.45' }

    # Act
    badges = ProjectDeps.badges(direct, 'custom')

    # Assert
    expected = [
      { 'group' => 'foundation', 'crate' => 'custom', 'version' => nil },
      { 'group' => 'tls', 'crate' => 'rustls', 'version' => '0.23.45' }
    ]
    assert_equal expected, badges
  end

  def test_builds_a_lock_url_from_a_github_repo_url
    # Arrange
    repo = 'https://github.com/vicanso/pingap'

    # Act
    url = ProjectDeps.lock_url(repo)

    # Assert
    assert_equal 'https://raw.githubusercontent.com/vicanso/pingap/HEAD/Cargo.lock', url
  end

  def test_lock_url_is_nil_for_a_non_github_repo
    # Arrange
    repo = 'https://codeberg.org/someone/proxy'

    # Act
    url = ProjectDeps.lock_url(repo)

    # Assert
    assert_nil url
  end

  def test_collect_skips_libraries_missing_locks_and_projects_with_no_badges
    # Arrange
    projects = [
      { 'name' => 'pingap', 'repo' => 'https://github.com/vicanso/pingap', 'kind' => 'program' },
      { 'name' => 'pingora', 'repo' => 'https://github.com/cloudflare/pingora', 'kind' => 'library' },
      { 'name' => 'gone', 'repo' => 'https://github.com/nobody/gone', 'kind' => 'program' },
      { 'name' => 'plain', 'repo' => 'https://github.com/nobody/plain', 'kind' => 'program' }
    ]
    locks = {
      'https://raw.githubusercontent.com/vicanso/pingap/HEAD/Cargo.lock' => PINGAP_LOCK,
      'https://raw.githubusercontent.com/cloudflare/pingora/HEAD/Cargo.lock' => PINGAP_LOCK,
      'https://raw.githubusercontent.com/nobody/plain/HEAD/Cargo.lock' => "[[package]]\nname = \"plain\"\nversion = \"0.1.0\"\ndependencies = [\n \"tokio\",\n]\n\n[[package]]\nname = \"tokio\"\nversion = \"1.0.0\"\nsource = \"registry+x\"\n"
    }
    fetcher = ->(url) { locks[url] }

    # Act
    result = ProjectDeps.collect(projects, fetcher)

    # Assert
    expected = {
      'https://github.com/vicanso/pingap' => [
        { 'group' => 'foundation', 'crate' => 'pingora', 'version' => '0.9.0' },
        { 'group' => 'tls', 'crate' => 'rustls', 'version' => '0.23.44' }
      ]
    }
    assert_equal expected, result
  end

  def test_collect_reads_the_lock_from_deps_repo_but_keys_the_result_by_repo
    # Arrange
    projects = [{ 'name' => 'Linkerd', 'repo' => 'https://github.com/linkerd/linkerd2', 'deps_repo' => 'https://github.com/linkerd/linkerd2-proxy', 'kind' => 'program' }]
    requested = []
    fetcher = ->(url) { requested << url; PINGAP_LOCK }

    # Act
    result = ProjectDeps.collect(projects, fetcher)

    # Assert
    assert_equal ['https://raw.githubusercontent.com/linkerd/linkerd2-proxy/HEAD/Cargo.lock'], requested
    assert_equal ['https://github.com/linkerd/linkerd2'], result.keys
  end

  def test_collect_passes_the_foundation_override_from_the_project_entry
    # Arrange
    projects = [{ 'name' => 'sozu', 'repo' => 'https://github.com/sozu-proxy/sozu', 'kind' => 'program', 'foundation' => 'custom' }]
    fetcher = ->(_url) { PINGAP_LOCK }

    # Act
    result = ProjectDeps.collect(projects, fetcher)

    # Assert
    assert_equal 'custom', result['https://github.com/sozu-proxy/sozu'].first['crate']
  end
end
