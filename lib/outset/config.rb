# frozen_string_literal: true

require "fileutils"

module Outset
  class Config
    CONFIG_DIR  = File.expand_path("~/.outset")
    CONFIG_FILE = File.join(CONFIG_DIR, "config.toml")

    DEFAULTS = {
      "defaults" => {
        "database"   => "postgresql",
        "css"        => "tailwind",
        "javascript" => "importmap"
      },
      "skip" => {
        "rubocop"  => false,
        "brakeman" => false,
        "docker"   => false
      },
      "gems" => {
        "always" => []
      },
      "recipes" => {
        "default" => nil
      }
    }.freeze

    def self.load
      new.load
    end

    def load
      return DEFAULTS.dup unless File.exist?(CONFIG_FILE)

      require "toml-rb"
      user_config = TomlRB.load_file(CONFIG_FILE)
      deep_merge(DEFAULTS.dup, user_config)
    rescue => e
      UI.warn("Could not read config file: #{e.message}. Using defaults.")
      DEFAULTS.dup
    end

    def self.resolve(options = {})
      config = load
      {
        "database"   => options[:database]           || ENV["OUTSET_DATABASE"] || config.dig("defaults", "database"),
        "css"        => options[:css]                || ENV["OUTSET_CSS"]      || config.dig("defaults", "css"),
        "javascript" => options[:js]                 || ENV["OUTSET_JS"]       || config.dig("defaults", "javascript"),
        "gems"       => config.dig("gems", "always") || []
      }
    end

    def self.init!
      return if File.exist?(CONFIG_FILE)

      FileUtils.mkdir_p(CONFIG_DIR)
      File.write(CONFIG_FILE, default_toml)
      UI.success("Created config file at #{CONFIG_FILE}")
    end

    def self.default_toml
      <<~TOML
        # ~/.outset/config.toml
        # Edit this file to set your personal defaults.

        [defaults]
        database   = "postgresql"
        css        = "tailwind"
        javascript = "importmap"

        [skip]
        rubocop  = false
        brakeman = false
        docker   = false

        [gems]
        always = []  # Gems added to every new app, e.g. ["annotate", "letter_opener"]

        [recipes]
        default = ""  # Name of your default recipe, e.g. "saas"
      TOML
    end

    private

    def deep_merge(base, override)
      base.merge(override) do |_key, base_val, override_val|
        if base_val.is_a?(Hash) && override_val.is_a?(Hash)
          deep_merge(base_val, override_val)
        else
          override_val
        end
      end
    end
  end
end
