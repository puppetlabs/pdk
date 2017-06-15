source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

gem 'metadata-json-lint'
gem 'puppet-lint'
gem 'rubocop'

# avoid newer versions that do not support ruby 2.1 anymore
gem 'nokogiri', '1.7.2'

group(:development, :test) do
  gem 'pry-byebug', '~> 3.4'
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3.0'
  gem 'rubocop-rspec'
end

group :acceptance do
  gem 'beaker-hostgenerator'
  gem 'serverspec'
end
