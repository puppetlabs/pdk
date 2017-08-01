source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

# avoid newer versions that do not support ruby 2.1 anymore
gem 'nokogiri', '1.7.2'

group :development do
  gem 'activesupport', '4.2.9'
  # TODO: Use gem instead of git. Section mapping is merged into master, but not yet released
  gem 'github_changelog_generator', git: 'https://github.com/skywinder/github-changelog-generator.git', ref: '33f89614d47a4bca1a3ae02bdcc37edd0b012e86'
  gem 'pry-byebug', '~> 3.4'
  if RUBY_VERSION < '2.2.2'
    # required for github_changelog_generator
    gem 'rack', '~> 1.0'
  end
  gem 'ruby-prof'
  gem 'yard'
end

group :test do
  gem 'coveralls'
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3.0'
  gem 'rspec-xsd'
  gem 'rubocop', '= 0.49.1'
  gem 'rubocop-rspec', '= 1.15.1'
end

group :acceptance do
  gem 'serverspec'
end
