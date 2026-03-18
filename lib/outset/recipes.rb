# frozen_string_literal: true

module Outset
  module Recipes
    REGISTRY = {
      "saas" => {
        description: "Full SaaS stack — auth, jobs, pagination",
        database:    "postgresql",
        css:         "tailwind",
        js:          "importmap",
        gems:        %w[devise pundit sidekiq pagy annotate letter_opener]
      },
      "api" => {
        description: "API-only app — no frontend assets",
        database:    "postgresql",
        css:         "none",
        js:          "importmap",
        gems:        %w[devise rspec]
      },
      "minimal" => {
        description: "Bare minimum — SQLite, no extras",
        database:    "sqlite3",
        css:         "none",
        js:          "importmap",
        gems:        []
      }
    }.freeze

    def self.find(name)
      REGISTRY[name] || user_recipes[name] || begin
        UI.error("Unknown recipe: '#{name}'")
        UI.muted("  Available recipes: #{all.keys.join(", ")}")
        exit(1)
      end
    end

    def self.all
      REGISTRY.merge(user_recipes)
    end

    def self.user_recipes
      config = Config.load
      (config["recipes"] || {}).each_with_object({}) do |(name, value), hash|
        next unless value.is_a?(Hash)
        hash[name] = {
          description: value["description"] || "Custom recipe",
          database:    value["database"]    || "postgresql",
          css:         value["css"]         || "tailwind",
          js:          value["js"]          || "importmap",
          gems:        value["gems"]        || []
        }
      end
    end
  end
end
