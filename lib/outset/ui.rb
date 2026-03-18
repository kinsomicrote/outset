# frozen_string_literal: true

require "pastel"

module Outset
  module UI
    PASTEL = Pastel.new

    def self.banner
      puts PASTEL.bold.blue(<<~BANNER)
          ___   _   _  _____  ____   _____  _____
         / _ \\ | | | ||_   _|/ ___| | ____|_   _|
        | | | || | | |  | |  \\___ \\ |  _|    | |
        | |_| || |_| |  | |   ___) || |___   | |
         \\___/  \\___/   |_|  |____/ |_____|  |_|
      BANNER
      puts PASTEL.dim("  Rails Application Bootstrapper v#{Outset::VERSION}")
      puts
    end

    def self.success(msg)  = puts PASTEL.green("✓ #{msg}")
    def self.error(msg)    = puts PASTEL.red("✗ #{msg}")
    def self.info(msg)     = puts PASTEL.cyan("→ #{msg}")
    def self.warn(msg)     = puts PASTEL.yellow("! #{msg}")
    def self.muted(msg)    = puts PASTEL.dim(msg)
  end
end
