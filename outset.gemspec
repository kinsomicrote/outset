# frozen_string_literal: true

require_relative "lib/outset/version"

Gem::Specification.new do |spec|
  spec.name    = "outset"
  spec.version = Outset::VERSION
  spec.authors = ["Kingsley Chijioke"]
  spec.email   = ["dev@kingsleychijioke.me"]

  spec.license     = "MIT"
  spec.summary     = "Bootstrap new Rails applications your way"
  spec.description = "A personal Rails application bootstrapper with interactive prompts, " \
                     "a config file, and predefined recipes — callable as `outset new <app_name>`."
  spec.homepage    = "https://github.com/kinsomicrote/outset"

  spec.required_ruby_version = ">= 3.1.0"

  spec.files         = Dir.glob("{exe,lib}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  spec.bindir        = "exe"
  spec.executables   = ["outset"]
  spec.require_paths = ["lib"]

  spec.add_dependency "thor",       "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "toml-rb",    ">= 3", "< 5"
  spec.add_dependency "pastel",     "~> 0.8"

  spec.add_development_dependency "minitest",           "~> 5.20"
  spec.add_development_dependency "minitest-reporters", "~> 1.6"
  spec.add_development_dependency "rake",               "~> 13.0"
end
