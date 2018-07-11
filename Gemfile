source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

if RUBY_VERSION < '2.4.0'
  # avoid newer versions that do not support ruby 2.1 anymore
  gem 'nokogiri', '1.7.2'
else
  # rubocop:disable Bundler/DuplicatedGem
  gem 'nokogiri', '~> 1.8.2'
end

group :development do
  gem 'activesupport', '4.2.9'
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
  gem 'parser', '~> 2.5.1.2'
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
