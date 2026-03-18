# frozen_string_literal: true

require "test_helper"

class NewCommandTest < Minitest::Test
  def setup
    @valid_options = { "yes" => true }
  end

  # ── App name validation ──────────────────────────────────────────────────

  def test_valid_snake_case_name_passes_validation
    cmd = build_cmd("my_app")
    assert_silent { cmd.send(:validate_app_name!) }
  end

  def test_name_with_spaces_exits
    cmd = build_cmd("my app")
    assert_raises(SystemExit) { cmd.send(:validate_app_name!) }
  end

  def test_name_starting_with_number_exits
    cmd = build_cmd("1app")
    assert_raises(SystemExit) { cmd.send(:validate_app_name!) }
  end

  def test_name_with_uppercase_exits
    cmd = build_cmd("MyApp")
    assert_raises(SystemExit) { cmd.send(:validate_app_name!) }
  end

  # ── Rails flag building ──────────────────────────────────────────────────

  def test_includes_database_flag
    flags = build_cmd("test_app").send(:build_rails_flags, {
      database: "postgresql", css: "tailwind", js: "importmap", gems: []
    })
    assert_includes flags, "--database=postgresql"
  end

  def test_adds_skip_test_when_rspec_is_selected
    flags = build_cmd("test_app").send(:build_rails_flags, {
      database: "postgresql", css: "tailwind", js: "importmap", gems: ["rspec"]
    })
    assert_includes flags, "--skip-test"
  end

  def test_does_not_add_skip_test_without_rspec
    flags = build_cmd("test_app").send(:build_rails_flags, {
      database: "postgresql", css: "tailwind", js: "importmap", gems: []
    })
    refute_includes flags, "--skip-test"
  end

  def test_skips_css_flag_when_none_selected
    flags = build_cmd("test_app").send(:build_rails_flags, {
      database: "postgresql", css: "none", js: "importmap", gems: []
    })
    assert_nil flags.find { |f| f.start_with?("--css") }
  end

  # ── Template generation ──────────────────────────────────────────────────

  def test_template_includes_gem_declarations
    template = build_cmd("test_app").send(:build_template, ["devise", "pundit"])
    assert_includes template, "gem 'devise'"
    assert_includes template, "gem 'pundit'"
  end

  def test_template_wraps_rspec_in_gem_group
    template = build_cmd("test_app").send(:build_template, ["rspec"])
    assert_includes template, "gem_group :development, :test"
    assert_includes template, "gem 'rspec-rails'"
    assert_includes template, "gem 'factory_bot_rails'"
  end

  def test_template_includes_after_bundle_block
    template = build_cmd("test_app").send(:build_template, ["devise"])
    assert_includes template, "after_bundle do"
    assert_includes template, "generate 'devise:install'"
  end

  def test_template_includes_git_commit
    template = build_cmd("test_app").send(:build_template, [])
    assert_includes template, "git add:"
    assert_includes template, "Initial scaffold via bottle"
  end

  private

  def build_cmd(app_name, options = @valid_options)
    Bottle::Commands::New.new(app_name, options)
  end
end
