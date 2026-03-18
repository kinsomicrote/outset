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
      REGISTRY[name] || begin
        UI.error("Unknown recipe: '#{name}'")
        UI.muted("  Available recipes: #{REGISTRY.keys.join(", ")}")
        exit(1)
      end
    end

    def self.all
      REGISTRY
    end
  end
end
