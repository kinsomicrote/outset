# outset

> Bootstrap new Rails applications your way — with an interactive wizard, persistent config, and named recipes.

Outset is a personal Rails application bootstrapper. Instead of trying to remember the flags you need to bootstrap a new Rails application, you can simply run `outset new myapp` and you'll get an interactive menu.

Inspired by [Suspenders](https://github.com/thoughtbot/suspenders) — thoughtbot's opinionated Rails app generator, but with a twist; it let's you set up your own recipes (config) that you can reuse across projects.

---

## Why not just use a Rails template?

Rails has a perfectly good [template API](https://guides.rubyonrails.org/rails_application_templates.html). You can pass a `template.rb` file — or a URL — to `rails new` and it will install gems, run generators, and modify files for you. So why outset?

| Capability                        | Rails template                                    | outset                                      |
| --------------------------------- | ------------------------------------------------- | ------------------------------------------- |
| Interactive gem picker            | No — hardcoded in the file                        | Yes — multi-select prompt                   |
| Persistent preferences            | No — pass flags every time                        | Yes — `~/.outset/config.toml`               |
| Config precedence                 | Not built in                                      | CLI flag › env var › config file › defaults |
| Named presets ("recipes")         | Multiple files, or one giant conditional template | `outset new myapp -r saas`                  |
| Discover available presets        | Open the file                                     | `outset recipes`                            |
| App name + environment validation | Template crashes or fails silently                | Built-in checks + `outset doctor`           |
| Team onboarding                   | Share a URL                                       | `gem install outset` + shared config        |

The key difference: outset is not trying to replace the expressive power of Rails templates. It _generates_ a `template.rb` behind the scenes and passes it to `rails new --template=...`. What it adds is everything **around** the template — the interactive UI, the config layer, and the recipe system — so you're not rewriting flags and remembering gem names every time you start a project.

Think of a Rails template as a low-level primitive and outset as the tool that manages and runs those primitives for you.

---

## Features

- **Interactive wizard** — choose database, CSS framework, JS bundler, and gems from a menu
- **Skip what you know** — pass flags to bypass individual prompts (`--database=postgresql`)
- **Persistent config** — save your defaults in `~/.outset/config.toml` (TOML format)
- **Config precedence** — CLI flags › `OUTSET_*` env vars › config file › built-in defaults
- **Always-gems** — declare gems that should be added to _every_ new app
- **Recipes** — named presets (built-in: `saas`, `api`, `minimal`; plus your own custom ones)
- **`outset doctor`** — pre-flight check that validates your environment before you waste time on a broken scaffold

---

## Installation

```bash
gem install outset
```

Requires Ruby ≥ 3.1 and Rails installed separately (`gem install rails`).

---

## Usage

### `outset new APP_NAME`

Bootstrap a new Rails application.

```bash
outset new my_app                    # interactive wizard
outset new my_app --yes              # accept all defaults, skip every prompt
outset new my_app -r saas            # use the built-in 'saas' recipe
outset new my_app -d mysql -c bootstrap  # skip specific prompts with flags
```

**Flags:**

| Flag         | Alias | Description                                                             |
| ------------ | ----- | ----------------------------------------------------------------------- |
| `--database` | `-d`  | Database adapter (`postgresql`, `mysql`, `sqlite3`)                     |
| `--css`      | `-c`  | CSS framework (`tailwind`, `bootstrap`, `sass`, `postcss`, `none`)      |
| `--js`       | `-j`  | JavaScript bundler (`importmap`, `esbuild`, `bun`, `webpack`, `rollup`) |
| `--recipe`   | `-r`  | Use a named recipe (see below)                                          |
| `--yes`      | `-y`  | Accept all defaults, skip all prompts                                   |

### `outset recipes`

List all available recipes (built-in and your own custom ones).

```bash
outset recipes
```

### `outset config [ACTION]`

View or manage your outset config file.

```bash
outset config show   # print current config (default)
outset config init   # create ~/.outset/config.toml with defaults
outset config edit   # open config file in $EDITOR
```

### `outset doctor`

Check that your environment is ready to use outset.

```bash
outset doctor
```

Verifies: Ruby version, Rails installation, Bundler, Git, Node.js (optional), and your config file.

### `outset version`

```bash
outset version   # or: outset -v
```

---

## Configuration

Running `outset config init` creates `~/.outset/config.toml`:

```toml
# ~/.outset/config.toml

[defaults]
database   = "postgresql"
css        = "tailwind"
javascript = "importmap"

[skip]
rubocop  = false
brakeman = false
docker   = false

[gems]
always = []  # Added to every new app, e.g. ["annotate", "letter_opener"]

[recipes]
default = ""  # Name of your default recipe, e.g. "saas"
```

**Config precedence (highest → lowest):**

1. CLI flags (`--database=mysql`)
2. Environment variables (`OUTSET_DATABASE`, `OUTSET_CSS`, `OUTSET_JS`)
3. `~/.outset/config.toml`
4. Built-in defaults (postgresql, tailwind, importmap)

---

## Recipes

A recipe is a named preset that pre-fills all selections. Pass one with `-r`:

```bash
outset new myapp -r saas
```

You can still override individual fields with flags even when using a recipe:

```bash
outset new myapp -r saas --database=mysql   # saas recipe, but MySQL instead of PostgreSQL
```

### Built-in recipes

| Recipe    | Database   | CSS      | JS        | Gems                                                   |
| --------- | ---------- | -------- | --------- | ------------------------------------------------------ |
| `saas`    | postgresql | tailwind | importmap | devise, pundit, sidekiq, pagy, annotate, letter_opener |
| `api`     | postgresql | none     | importmap | devise, rspec                                          |
| `minimal` | sqlite3    | none     | importmap | —                                                      |

### Custom recipes

Add your own recipes to `~/.outset/config.toml`:

```toml
[recipes.mystartup]
description = "My startup stack"
database    = "postgresql"
css         = "tailwind"
js          = "esbuild"
gems        = ["devise", "sidekiq", "pagy"]
```

Then use it like any other recipe:

```bash
outset new myapp -r mystartup
```

Custom recipes pick up any `[gems] always` entries automatically — you won't get duplicates.

---

## How it works internally

When you run `outset new myapp`:

1. **Validate** — app name format check, check for existing directory, confirm Rails is installed
2. **Select** — interactive prompts (or recipe / `--yes` to skip)
3. **Build flags** — translate selections into `rails new` flags (`--database`, `--css`, etc.)
4. **Generate template** — if gems were selected, write a temporary `template.rb` using the Rails template DSL and pass it via `--template=path`
5. **Run** — execute `rails new` inside `Bundler.with_unbundled_env` so it runs outside outset's own bundle context
6. **Clean up** — delete the temp template file, print next steps

The generated template uses Rails' own template DSL:

```ruby
gem 'devise'
gem_group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
end
after_bundle do
  generate 'devise:install'
  generate 'devise', 'User'
  git add: '.', commit: %(-m 'Initial scaffold via outset')
end
```

---

## Development

```bash
git clone https://github.com/kinsomicrote/outset
cd outset
bundle install
bundle exec rake test      # run the test suite
bundle exec exe/outset version
bundle exec exe/outset doctor
```

To install the gem locally:

```bash
bundle exec rake install
```

---

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kinsomicrote/outset.
