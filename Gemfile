# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

group :development do
  gem 'activesupport', '4.2.9'
  # TODO: Use gem instead of git. Section mapping is merged into master, but not yet released
  gem 'github_changelog_generator', '~> 1.14'
  gem 'pry-byebug', '~> 3.4'
  if RUBY_VERSION < '2.2.2'
    # byebug >= 9.1.0 requires ruby 2.2.0 or newer
    gem 'byebug', '~> 9.0.6'
    # required for github_changelog_generator
    gem 'rack', '~> 1.0'
  end
  gem 'ruby-prof'
  gem 'yard'
end

group :test do
  gem 'coveralls'
  gem 'license_finder', '~> 3.0.4'
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3.0'
  gem 'rspec-xsd'
  gem 'rubocop', '= 0.49.1'
  gem 'rubocop-rspec', '= 1.15.1'
  gem 'simplecov-console'
end

group :acceptance do
  gem 'serverspec'
end
