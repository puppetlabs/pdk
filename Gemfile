source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

gem 'metadata-json-lint'
gem 'rubocop'

group(:development, :test) do
  gem 'bundler', '~> 1.13'
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3.0'
  gem 'pry-byebug', '~> 3.4'
  gem 'rubocop-rspec'
end

group :acceptance do
  gem 'beaker-rspec'
  gem 'beaker-hostgenerator'
  gem 'beaker-testmode_switcher'
end

