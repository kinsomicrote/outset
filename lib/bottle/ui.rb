# frozen_string_literal: true

require "pastel"

module Bottle
  module UI
    PASTEL = Pastel.new

    def self.banner
      puts PASTEL.bold.blue(<<~BANNER)
         _           _   _   _
        | |__   ___ | |_| |_| | ___
        | '_ \\ / _ \\| __| __| |/ _ \\
        | |_) | (_) | |_| |_| |  __/
        |_.__/ \\___/ \\__|\\__|_|\\___|
      BANNER
      puts PASTEL.dim("  Rails Application Bootstrapper v#{Bottle::VERSION}")
      puts
    end

    def self.success(msg)  = puts PASTEL.green("✓ #{msg}")
    def self.error(msg)    = puts PASTEL.red("✗ #{msg}")
    def self.info(msg)     = puts PASTEL.cyan("→ #{msg}")
    def self.warn(msg)     = puts PASTEL.yellow("! #{msg}")
    def self.muted(msg)    = puts PASTEL.dim(msg)
  end
end
