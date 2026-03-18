# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  # A known config to stub Config.load with — simulates a user config file
  # that differs from built-in defaults so we can detect when it's being used.
  STUB_CONFIG = {
    "defaults" => { "database" => "mysql", "css" => "bootstrap", "javascript" => "esbuild" },
    "gems"     => { "always" => ["annotate"] }
  }.freeze

  # ── Config.resolve precedence ────────────────────────────────────────────

  def test_cli_flag_wins_over_env_and_config
    with_env("OUTSET_DATABASE" => "sqlite3") do
      Outset::Config.stub(:load, STUB_CONFIG) do
        result = Outset::Config.resolve(database: "postgresql")
        assert_equal "postgresql", result["database"]
      end
    end
  end

  def test_env_var_wins_over_config_file
    with_env("OUTSET_DATABASE" => "sqlite3") do
      Outset::Config.stub(:load, STUB_CONFIG) do
        result = Outset::Config.resolve({})
        assert_equal "sqlite3", result["database"]
      end
    end
  end

  def test_config_file_wins_over_built_in_defaults
    Outset::Config.stub(:load, STUB_CONFIG) do
      result = Outset::Config.resolve({})
      assert_equal "mysql",    result["database"]
      assert_equal "bootstrap", result["css"]
      assert_equal "esbuild",  result["javascript"]
    end
  end

  def test_built_in_defaults_used_when_nothing_else_set
    bare_config = { "defaults" => Outset::Config::DEFAULTS["defaults"], "gems" => { "always" => [] } }
    Outset::Config.stub(:load, bare_config) do
      result = Outset::Config.resolve({})
      assert_equal "postgresql", result["database"]
      assert_equal "tailwind",   result["css"]
      assert_equal "importmap",  result["javascript"]
    end
  end

  def test_always_gems_included_in_resolved_config
    Outset::Config.stub(:load, STUB_CONFIG) do
      result = Outset::Config.resolve({})
      assert_equal ["annotate"], result["gems"]
    end
  end

  private

  def with_env(vars)
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    vars.each_key { |k| ENV.delete(k) }
  end
end
