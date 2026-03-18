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

  # ── User recipes from config ──────────────────────────────────────────────

  def test_user_recipe_is_found
    stub_config = { "recipes" => { "mystartup" => {
      "description" => "My startup", "database" => "mysql",
      "css" => "bootstrap", "js" => "esbuild", "gems" => ["devise"]
    }}}
    Outset::Config.stub(:load, stub_config) do
      recipe = Outset::Recipes.find("mystartup")
      assert_equal "mysql",     recipe[:database]
      assert_equal "bootstrap", recipe[:css]
      assert_equal "esbuild",   recipe[:js]
    end
  end

  def test_user_recipe_keys_are_symbolized
    stub_config = { "recipes" => { "myrecipe" => {
      "database" => "sqlite3", "css" => "none", "js" => "importmap", "gems" => []
    }}}
    Outset::Config.stub(:load, stub_config) do
      recipe = Outset::Recipes.find("myrecipe")
      assert recipe.key?(:database), "expected symbol key :database"
    end
  end

  def test_all_includes_user_recipes
    stub_config = { "recipes" => { "custom" => {
      "database" => "postgresql", "css" => "tailwind",
      "js" => "importmap", "gems" => []
    }}}
    Outset::Config.stub(:load, stub_config) do
      assert_includes Outset::Recipes.all.keys, "custom"
      assert_includes Outset::Recipes.all.keys, "saas"
    end
  end

  def test_user_recipe_defaults_missing_fields
    stub_config = { "recipes" => { "sparse" => { "database" => "sqlite3" } } }
    Outset::Config.stub(:load, stub_config) do
      recipe = Outset::Recipes.find("sparse")
      assert_equal "tailwind",  recipe[:css]
      assert_equal "importmap", recipe[:js]
      assert_equal [],          recipe[:gems]
    end
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
    Outset::Config.stub(:resolve, {
      "database" => "sqlite3", "css" => "none",
      "javascript" => "importmap", "gems" => []
    }) do
      cmd = build_cmd("test_app", recipe: "minimal")
      selections = cmd.send(:recipe_selections)
      assert_empty selections[:gems]
    end
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
