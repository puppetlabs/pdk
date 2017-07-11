source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

# avoid newer versions that do not support ruby 2.1 anymore
gem 'nokogiri', '1.7.2'

group :development do
  gem 'activesupport', '4.2.9'
  gem 'github_changelog_generator', git: 'https://github.com/DavidS/github-changelog-generator.git', ref: 'adjust-tag-section-mapping'
  gem 'pry-byebug', '~> 3.4'
  if RUBY_VERSION < '2.2.2'
    # required for github_changelog_generator
    gem 'rack', '~> 1.0'
  end
  gem 'ruby-prof'
end

group :test do
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3.0'
  gem 'parallel_tests'
  gem 'rspec-xsd'
  gem 'rubocop', '= 0.49.1'
  gem 'rubocop-rspec', '= 1.15.1'
end

group :acceptance do
  gem 'serverspec'
end

# beaker should not be installed on the SUT during package testing
group :package_testing do
  gem 'beaker'
end
