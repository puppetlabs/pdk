source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

gem 'metadata-json-lint'
gem 'puppet-lint'

# avoid newer versions that do not support ruby 2.1 anymore
gem 'nokogiri', '1.7.2'

group :development do
  gem 'pry-byebug', '~> 3.4'
end

group :test do
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '= 0.49.1'
  gem 'rubocop-rspec', '= 1.15.1'
end

group :acceptance do
  gem 'beaker-hostgenerator'
  gem 'serverspec'
end
