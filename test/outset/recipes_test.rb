# frozen_string_literal: true

require "test_helper"

class RecipesTest < Minitest::Test
  # ── Registry ─────────────────────────────────────────────────────────────

  def test_saas_recipe_exists
    recipe = Outset::Recipes::REGISTRY["saas"]
    refute_nil recipe
  end

  def test_api_recipe_exists
    recipe = Outset::Recipes::REGISTRY["api"]
    refute_nil recipe
  end

  def test_minimal_recipe_exists
    recipe = Outset::Recipes::REGISTRY["minimal"]
    refute_nil recipe
  end

  # ── Recipes.find ─────────────────────────────────────────────────────────

  def test_find_returns_recipe_by_name
    recipe = Outset::Recipes.find("saas")
    assert_equal "postgresql", recipe[:database]
    assert_equal "tailwind",   recipe[:css]
    assert_includes recipe[:gems], "devise"
  end

  def test_find_exits_on_unknown_recipe
    assert_raises(SystemExit) { Outset::Recipes.find("nonexistent") }
  end

  # ── Recipe selections in New command ─────────────────────────────────────

  def test_recipe_sets_database
    cmd = build_cmd("test_app", recipe: "saas")
    selections = cmd.send(:recipe_selections)
    assert_equal "postgresql", selections[:database]
  end

  def test_recipe_sets_gems
    cmd = build_cmd("test_app", recipe: "saas")
    selections = cmd.send(:recipe_selections)
    assert_includes selections[:gems], "devise"
    assert_includes selections[:gems], "sidekiq"
  end

  def test_cli_flag_overrides_recipe_database
    cmd = build_cmd("test_app", recipe: "saas", database: "mysql")
    selections = cmd.send(:recipe_selections)
    assert_equal "mysql", selections[:database]
  end

  def test_minimal_recipe_has_no_gems
    cmd = build_cmd("test_app", recipe: "minimal")
    selections = cmd.send(:recipe_selections)
    assert_empty selections[:gems]
  end

  def test_always_gems_merged_with_recipe_gems
    Outset::Config.stub(:resolve, {
      "database" => "postgresql", "css" => "tailwind",
      "javascript" => "importmap", "gems" => ["annotate"]
    }) do
      cmd = build_cmd("test_app", recipe: "minimal")
      selections = cmd.send(:recipe_selections)
      assert_includes selections[:gems], "annotate"
    end
  end

  private

  def build_cmd(app_name, options = {})
    Outset::Commands::New.new(app_name, options)
  end
end
