# Gitolite Admin repository management
gem 'gitolite-rugged', git: 'https://github.com/jbox-web/gitolite-rugged.git', tag: '1.2.0'

# Ruby/Rack Git Smart-HTTP Server Handler
gem 'gitlab-grack', '~> 2.0.0', git: 'https://github.com/jbox-web/grack.git', require: 'grack', branch: 'fix_gemfile'

# Memcached client for GitCache
gem 'dalli'

# Redis client for GitCache
gem 'redis'
gem 'hiredis'

# Markdown rendering
gem 'escape_utils'
gem 'html-pipeline'
gem 'rinku'

# Syntaxic coloration
gem 'github-markup'
gem 'RedCloth'
gem 'org-ruby'
gem 'creole'
gem 'asciidoctor'

# Rack parser for Hrack
gem 'rack-parser', require: 'rack/parser'

# temp autoloading fix
gem 'sidekiq'
gem 'sshkey'

group :development, :test do
  gem 'rspec'
  gem 'rspec-rails', '~> 3.5', '>= 3.5.2'
  gem 'rails-controller-testing'

  gem 'shoulda', '~> 3.5.0'
  gem 'shoulda-context'
  gem 'shoulda-matchers', '~> 2.7.0'

  gem 'database_cleaner'
  gem 'factory_bot_rails', '< 5.0'

  gem 'rubocop', require: false
  gem 'rubocop-rspec'

  # Publish to CodeClimate
  gem 'codeclimate-test-reporter', require: false
end

group :development do
  gem 'brakeman'
  gem 'bullet'
  gem 'spring'
  gem 'spring-commands-rspec'
end
