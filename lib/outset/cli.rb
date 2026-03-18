# frozen_string_literal: true

require "thor"
require_relative "commands/new"
require_relative "commands/config_cmd"
require_relative "commands/doctor"

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

    desc "version", "Print outset version"
    def version
      puts "outset v#{Outset::VERSION}"
    end

    map %w[--version -v] => :version
  end
end
