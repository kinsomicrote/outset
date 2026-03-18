# frozen_string_literal: true

require "test_helper"

class VersionTest < Minitest::Test
  def test_has_a_version_number
    refute_nil Bottle::VERSION
  end

  def test_version_follows_semver_format
    assert_match(/\A\d+\.\d+\.\d+/, Bottle::VERSION)
  end
end
