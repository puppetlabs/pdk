source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

gem 'metadata-json-lint'
gem 'rubocop'

# avoid newer versions that do not support ruby 2.1 anymore
gem 'nokogiri', '1.7.2'

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
