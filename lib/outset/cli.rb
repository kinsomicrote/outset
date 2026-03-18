# frozen_string_literal: true

require "thor"
require_relative "commands/new"
require_relative "commands/config_cmd"
require_relative "commands/doctor"
require_relative "recipes"

module Outset
  class CLI < Thor
    def self.exit_on_failure? = true

    desc "new APP_NAME", "Bootstrap a new Rails application"
    option :database, aliases: "-d", type: :string,  default: nil,   desc: "Database (postgresql, mysql, sqlite3)"
    option :css,      aliases: "-c", type: :string,  default: nil,   desc: "CSS framework (tailwind, bootstrap, sass, postcss, none)"
    option :js,       aliases: "-j", type: :string,  default: nil,   desc: "JavaScript bundler (importmap, esbuild, bun, webpack, rollup)"
    option :recipe,   aliases: "-r", type: :string,  default: nil,   desc: "Use a predefined recipe"
    option :yes,      aliases: "-y", type: :boolean, default: false, desc: "Accept all defaults, skip prompts"
    def new(app_name)
      UI.banner
      Commands::New.new(app_name, options).run
    end

    desc "config [ACTION]", "View or edit your outset config (~/.outset/config.toml)"
    def config(action = "show")
      Commands::ConfigCmd.new(action).run
    end

    desc "doctor", "Check that your environment is ready to use outset"
    def doctor
      UI.banner
      Commands::Doctor.new.run
    end

    desc "recipes", "List available recipes"
    def recipes
      UI.info("Available recipes:")
      puts
      Recipes.all.each do |name, recipe|
        puts "  #{UI::PASTEL.bold(name.ljust(10))} #{recipe[:description]}"
        UI.muted("    db=#{recipe[:database]}  css=#{recipe[:css]}  js=#{recipe[:js]}  gems=#{recipe[:gems].empty? ? "none" : recipe[:gems].join(", ")}")
        puts
      end
    end

    desc "version", "Print outset version"
    def version
      puts "outset v#{Outset::VERSION}"
    end

    map %w[--version -v] => :version
  end
end
