# frozen_string_literal: true

module Bottle
  module Commands
    class Doctor
      CHECKS = [
        {
          name: "Ruby >= 3.1",
          check: -> { RUBY_VERSION >= "3.1.0" },
          fix:   "Install Ruby 3.1+ via rbenv or asdf"
        },
        {
          name: "Rails installed",
          check: -> { system("which rails > /dev/null 2>&1") },
          fix:   "Run: gem install rails"
        },
        {
          name: "Git installed",
          check: -> { system("which git > /dev/null 2>&1") },
          fix:   "Install git from https://git-scm.com"
        },
        {
          name: "Git user.name configured",
          check: -> { !`git config user.name`.strip.empty? rescue false },
          fix:   "Run: git config --global user.name 'Your Name'"
        },
        {
          name: "Git user.email configured",
          check: -> { !`git config user.email`.strip.empty? rescue false },
          fix:   "Run: git config --global user.email 'you@example.com'"
        },
        {
          name: "Bottle config file",
          check: -> { File.exist?(Config::CONFIG_FILE) },
          fix:   "Run: bottle config init"
        }
      ].freeze

      def run
        UI.info("Checking your environment...\n")
        all_passed = true

        CHECKS.each do |check|
          if check[:check].call
            UI.success(check[:name])
          else
            UI.warn("#{check[:name]}  →  #{check[:fix]}")
            all_passed = false
          end
        end

        puts
        if all_passed
          UI.success("All checks passed. You're ready to use bottle!")
        else
          UI.warn("Some checks failed. Fix the issues above and run `bottle doctor` again.")
        end
      end
    end
  end
end
