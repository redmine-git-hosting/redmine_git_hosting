# Redmine Git Hosting Plugin

A Redmine plugin that enables Git hosting through Gitolite, providing repository management, SSH key handling, and Git Smart-HTTP functionality.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Critical: This is a Redmine Plugin, NOT a Standalone Application

**IMPORTANT**: This codebase is a Redmine plugin that requires a full Redmine installation to run. You cannot run this plugin independently. The plugin extends Redmine's functionality but must be installed within an existing Redmine application.

## Working Effectively

### Development Setup (Linting and Code Quality Only)
- Bootstrap development environment:
  - `sudo gem install bundler`
  - `touch .enable_dev` (enables development gems)
  - `bundle config set --local path 'vendor/bundle'`
  - `bundle install --jobs 4 --retry 3` -- takes 80 seconds. Set timeout to 120+ seconds.
  - `yarn install` -- takes 30 seconds. Set timeout to 60+ seconds.

### Linting and Code Quality (NEVER CANCEL - All Required for CI)
- `bundle exec rubocop -S` -- Ruby code linting, takes 2 seconds. NEVER CANCEL.
- `bundle exec slim-lint app/views` -- View template linting, takes 3 seconds. NEVER CANCEL.
- `node_modules/.bin/stylelint "assets/stylesheets/*.css"` -- CSS linting, takes 1 second. NEVER CANCEL.
- `bundle exec brakeman` -- Security scanning, takes 3 seconds. NEVER CANCEL.

### What You CANNOT Do (Plugin Limitations)
- **DO NOT** try to run this as a standalone Rails application
- **DO NOT** attempt `rails server` or similar - there is no main application
- **DO NOT** run `rake` commands directly - they require Redmine context
- **DO NOT** try to run RSpec tests without full Redmine setup
- **DO NOT** expect database migrations to work without Redmine

### Full Plugin Testing (Requires Redmine Installation)
**WARNING**: The following requires a complete Redmine setup and takes 45+ minutes:

Complete setup process (from .github/workflows/test.yml):
1. Install system dependencies:
   ```bash
   sudo apt-get update --yes --quiet
   sudo apt-get install --yes --quiet build-essential cmake libgpg-error-dev libicu-dev libpq-dev libmysqlclient-dev libssh2-1 libssh2-1-dev pkg-config subversion
   ```

2. Setup Redmine (clone redmine/redmine repository):
   ```bash
   git clone https://github.com/redmine/redmine.git /path/to/redmine
   cd /path/to/redmine
   ```

3. Install plugin and dependencies:
   ```bash
   # Clone this plugin into redmine/plugins/redmine_git_hosting
   # Clone required plugins:
   git clone https://github.com/AlphaNodes/additionals.git plugins/additionals
   git clone https://github.com/dosyfier/redmine_sidekiq.git plugins/redmine_sidekiq -b fix-rails-6
   ```

4. Setup Gitolite:
   ```bash
   # Install and configure Gitolite (see CI workflow for complete steps)
   ssh-keygen -N '' -f plugins/redmine_git_hosting/ssh_keys/redmine_gitolite_admin_id_rsa
   # Full Gitolite setup required...
   ```

5. Run tests (45+ minutes total):
   ```bash
   bundle exec rake redmine_git_hosting:ci:all
   ```
   **NEVER CANCEL** - Tests take 45+ minutes. Set timeout to 60+ minutes.

## Validation

### Always Run These Before Committing
- `bundle exec rubocop -S` -- fixes most style issues automatically
- `bundle exec slim-lint app/views` -- checks view templates
- `node_modules/.bin/stylelint "assets/stylesheets/*.css"` -- checks CSS
- `bundle exec brakeman` -- security scanning

### Validation Scenarios (Requires Full Redmine Setup)
Since this is a plugin, validation requires:
1. Full Redmine installation with this plugin
2. Gitolite server setup with SSH keys
3. Database configured (PostgreSQL or MySQL)
4. Test scenarios include:
   - Repository creation and management
   - SSH key management
   - Git Smart-HTTP functionality
   - Mirror and deployment credential management

## Common Tasks

### Repo Structure (ls -la output)
```
total 248
drwxr-xr-x  15 runner docker  4096 Aug 11 11:52 .
drwxr-xr-x   3 runner docker  4096 Aug 11 11:38 ..
drwxr-xr-x   2 runner docker  4096 Aug 11 11:41 .bundle
-rw-r--r--   1 runner docker     0 Aug 11 11:49 .enable_dev
drwxr-xr-x   7 runner docker  4096 Aug 11 11:47 .git
drwxr-xr-x   3 runner docker  4096 Aug 11 11:49 .github
-rw-r--r--   1 runner docker   183 Aug 11 11:38 .gitignore
-rw-r--r--   1 runner docker  2121 Aug 11 11:38 .rubocop.yml
-rw-r--r--   1 runner docker  8299 Aug 11 11:38 .rubocop_todo.yml
-rw-r--r--   1 runner docker  1270 Aug 11 11:38 .slim-lint.yml
-rw-r--r--   1 runner docker  5635 Aug 11 11:38 .stylelintrc.json
-rw-r--r--   1 runner docker  2478 Aug 11 11:38 AUTHORS
-rw-r--r--   1 runner docker 36496 Aug 11 11:38 CHANGELOG.md
-rw-r--r--   1 runner docker  1573 Aug 11 11:38 Gemfile
-rw-r--r--   1 runner docker  9468 Aug 11 11:51 Gemfile.lock
-rw-r--r--   1 runner docker  1046 Aug 11 11:38 LICENSE
-rw-r--r--   1 runner docker  1527 Aug 11 11:38 README.md
drwxr-xr-x  13 runner docker  4096 Aug 11 11:38 app
drwxr-xr-x   5 runner docker  4096 Aug 11 11:38 assets
drwxr-xr-x   3 runner docker  4096 Aug 11 11:38 config
drwxr-xr-x   5 runner docker  4096 Aug 11 11:38 contrib
-rw-r--r--   1 runner docker  1289 Aug 11 11:38 custom_hooks.rb.example
drwxr-xr-x   3 runner docker  4096 Aug 11 11:38 db
-rw-r--r--   1 runner docker  3561 Aug 11 11:38 init.rb
drwxr-xr-x   6 runner docker  4096 Aug 11 11:38 lib
drwxr-xr-x 79 runner docker  4096 Aug 11 11:52 node_modules
-rw-r--r--   1 runner docker   104 Aug 11 11:38 package.json
drwxr-xr-x  11 runner docker  4096 Aug 11 11:38 spec
drwxr-xr-x   2 runner docker  4096 Aug 11 11:38 ssh_keys
drwxr-xr-x   3 runner docker  4096 Aug 11 11:51 vendor
-rw-r--r--   1 runner docker 55068 Aug 11 11:52 yarn.lock
```

### Expected Linting Output Examples

RuboCop output (partial):
```
328 files inspected, 114 offenses detected, 75 offenses autocorrectable
```

Slim-lint output (partial):
```
app/views/repositories/_git_hosting_sidebar.html.slim:9 [W] RuboCop: Style/RedundantLineContinuation
app/views/settings/redmine_git_hosting/_gitolite_config_test.html.slim:95 [W] RuboCop: Style/RedundantRegexpArgument
```

StyleLint typically produces no output when CSS is clean.

Brakeman output (partial):
```
Confidence: Weak
Category: Dangerous Eval
Check: Evaluation
Message: Dynamic string evaluated as code
```

## Common Tasks

### Repo Structure
```
.
├── .github/workflows/     # CI/CD workflows
├── .rubocop.yml          # Ruby linting configuration
├── .slim-lint.yml        # Slim template linting
├── .stylelintrc.json     # CSS linting configuration
├── app/                  # Rails application components
│   ├── controllers/      # Plugin controllers
│   ├── models/          # Plugin models
│   ├── views/           # Slim templates
│   └── workers/         # Background job workers
├── assets/              # Static assets
│   ├── javascripts/     # JavaScript files
│   └── stylesheets/     # CSS files
├── lib/                 # Ruby libraries and core plugin code
├── spec/                # RSpec tests
├── Gemfile              # Ruby dependencies
├── init.rb              # Plugin initialization
└── package.json         # Node.js dependencies (for linting)
```

### Key Plugin Components
- **Gitolite Integration**: Repository hosting through Gitolite
- **SSH Key Management**: User SSH key handling
- **Git Smart-HTTP**: Web-based Git access
- **Repository Mirrors**: Repository mirroring functionality
- **Background Jobs**: Sidekiq-based async processing

### CI Requirements
The CI pipeline (.github/workflows/) requires:
- Ruby 2.7+ (supports up to 3.1)
- Redmine 4.1+ (supports up to master)
- PostgreSQL or MySQL database
- Gitolite installation
- System dependencies for Git/SSH operations

### Dependencies
- **Ruby Gems**: Defined in Gemfile (gitolite-rugged, gitlab-grack, etc.)
- **Node.js**: Only for development linting tools
- **System**: Git, SSH, Gitolite, database, build tools

### Development Notes
- Uses Slim templates for views
- Follows Rails/Redmine conventions
- Extensive test coverage with RSpec
- Security scanning with Brakeman
- Code style enforced with RuboCop

## Important Files to Check After Changes
- Always run all linting tools before committing
- Check `init.rb` when modifying plugin structure
- Review `lib/redmine_git_hosting.rb` for core functionality changes
- Update tests in `spec/` when adding new features
- Check `assets/` for frontend changes requiring CSS linting