# frozen_string_literal: true

require "tty-prompt"
require "tmpdir"

module Bottle
  module Commands
    class New
      DATABASES   = %w[postgresql mysql sqlite3].freeze
      CSS_OPTIONS = %w[tailwind bootstrap sass postcss none].freeze
      JS_OPTIONS  = %w[importmap esbuild bun webpack rollup].freeze

      OPTIONAL_GEMS = [
        { name: "Devise (Authentication)",      value: "devise"        },
        { name: "Pundit (Authorization)",       value: "pundit"        },
        { name: "Sidekiq (Background Jobs)",    value: "sidekiq"       },
        { name: "RSpec + FactoryBot (Tests)",   value: "rspec"         },
        { name: "Annotate (Model Annotations)", value: "annotate"      },
        { name: "Letter Opener (Email preview)",value: "letter_opener" },
        { name: "Pagy (Pagination)",            value: "pagy"          },
      ].freeze

      def initialize(app_name, options = {})
        @app_name = app_name
        @options  = options
        @resolved = Config.resolve(options)
        @prompt   = TTY::Prompt.new(interrupt: :exit)
      end

      def run
        validate_app_name!
        validate_rails_installed!

        selections = if @options[:yes]
                       default_selections
                     else
                       prompt_user
                     end

        confirm_and_run(selections)
      end

      private

      def validate_app_name!
        unless @app_name.match?(/\A[a-z][a-z0-9_]*\z/)
          UI.error("Invalid app name: '#{@app_name}'")
          UI.muted("  App names must start with a letter and contain only lowercase letters, numbers, and underscores.")
          exit(1)
        end

        if Dir.exist?(@app_name)
          UI.error("Directory '#{@app_name}' already exists.")
          exit(1)
        end
      end

      def validate_rails_installed!
        unless system("which rails > /dev/null 2>&1")
          UI.error("Rails is not installed. Run: gem install rails")
          exit(1)
        end
      end

      def default_selections
        {
          database: @resolved["database"],
          css:      @resolved["css"],
          js:       @resolved["javascript"],
          gems:     @resolved["gems"]
        }
      end

      def prompt_user
        UI.info("Configuring: #{@app_name}")
        puts

        database = @prompt.select("Database:", DATABASES,
                                  default: @resolved["database"])

        css = @prompt.select("CSS framework:", CSS_OPTIONS,
                             default: @resolved["css"])

        js = @prompt.select("JavaScript bundler:", JS_OPTIONS,
                            default: @resolved["javascript"])

        always_gems = @resolved["gems"]
        gems = @prompt.multi_select("Optional gems: (space to select, enter to confirm)") do |menu|
          OPTIONAL_GEMS.each do |gem_opt|
            preselected = always_gems.include?(gem_opt[:value])
            menu.choice gem_opt[:name], gem_opt[:value], disabled: (preselected ? "(always)" : false)
          end
        end
        gems += always_gems

        { database: database, css: css, js: js, gems: gems.uniq }
      end

      def confirm_and_run(selections)
        puts
        UI.info("Ready to create '#{@app_name}' with:")
        UI.muted("  Database : #{selections[:database]}")
        UI.muted("  CSS      : #{selections[:css]}")
        UI.muted("  JS       : #{selections[:js]}")
        UI.muted("  Gems     : #{selections[:gems].empty? ? "none" : selections[:gems].join(", ")}")
        puts

        return unless @options[:yes] || @prompt.yes?("Proceed?")

        generate(selections)
      end

      def generate(selections)
        rails_flags = build_rails_flags(selections)

        if selections[:gems].any?
          template_path = write_template(selections[:gems])
          rails_flags << "--template=#{template_path}"
        end

        cmd = "rails new #{@app_name} #{rails_flags.join(" ")}"
        UI.info("Running: #{cmd}")
        puts

        success = Bundler.with_unbundled_env { system(cmd) }

        File.delete(template_path) if template_path && File.exist?(template_path)

        if success
          puts
          UI.success("App created! Next steps:")
          UI.muted("  cd #{@app_name}")
          UI.muted("  bin/setup")
          UI.muted("  bin/dev")
        else
          UI.error("rails new failed. See output above for details.")
          exit(1)
        end
      end

      def build_rails_flags(selections)
        flags = []
        flags << "--database=#{selections[:database]}"
        flags << "--css=#{selections[:css]}"        unless selections[:css] == "none"
        flags << "--javascript=#{selections[:js]}"
        flags << "--skip-test" if selections[:gems].include?("rspec")
        flags
      end

      # Writes a temporary Rails template.rb file and returns its path
      def write_template(gems)
        template = build_template(gems)
        path = File.join(Dir.tmpdir, "bottle_template_#{@app_name}_#{Process.pid}.rb")
        File.write(path, template)
        path
      end

      def build_template(gems)
        lines = ["# Generated by bottle v#{Bottle::VERSION}", ""]

        # Gem declarations
        lines << "# ── Gems ─────────────────────────────────────────────"
        gems.each { |g| lines << gem_declaration(g) }
        lines << ""

        # after_bundle block
        lines << "after_bundle do"
        gems.each do |g|
          after = after_bundle_steps(g)
          lines += after.map { |l| "  #{l}" } if after.any?
        end
        lines << "  git add: '.', commit: %(-m 'Initial scaffold via bottle')"
        lines << "end"
        lines << ""

        lines.join("\n")
      end

      def gem_declaration(gem_name)
        case gem_name
        when "rspec"
          "gem_group :development, :test do\n  gem 'rspec-rails'\n  gem 'factory_bot_rails'\n  gem 'faker'\nend"
        when "letter_opener"
          "gem_group :development do\n  gem 'letter_opener'\nend"
        when "sidekiq"
          "gem 'sidekiq'"
        else
          "gem '#{gem_name}'"
        end
      end

      def after_bundle_steps(gem_name)
        case gem_name
        when "devise"  then ["generate 'devise:install'", "generate 'devise', 'User'"]
        when "pundit"  then ["generate 'pundit:install'"]
        when "rspec"   then ["generate 'rspec:install'", "rails_command 'db:create'"]
        when "sidekiq" then ["# Add Sidekiq as ActiveJob backend in config/application.rb manually"]
        else []
        end
      end
    end
  end
end
