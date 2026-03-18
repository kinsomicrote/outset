# frozen_string_literal: true

module Outset
  module Commands
    class ConfigCmd
      def initialize(action)
        @action = action
      end

      def run
        case @action
        when "show"   then show
        when "init"   then Config.init!
        when "edit"   then edit
        when "path"   then puts Config::CONFIG_FILE
        else
          UI.error("Unknown config action: '#{@action}'")
          UI.muted("  Available: show, init, edit, path")
          exit(1)
        end
      end

      private

      def show
        if File.exist?(Config::CONFIG_FILE)
          UI.info("Config file: #{Config::CONFIG_FILE}")
          puts
          puts File.read(Config::CONFIG_FILE)
        else
          UI.warn("No config file found. Run `outset config init` to create one.")
          puts
          UI.muted("Default values:")
          puts Config.default_toml
        end
      end

      def edit
        unless File.exist?(Config::CONFIG_FILE)
          Config.init!
        end
        editor = ENV["VISUAL"] || ENV["EDITOR"] || "nano"
        system("#{editor} #{Config::CONFIG_FILE}")
      end
    end
  end
end
