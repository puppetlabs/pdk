source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

def location_for(place_or_version, fake_version = nil)
  if place_or_version =~ %r{\A(git[:@][^#]*)#(.*)}
    [fake_version, { git: Regexp.last_match(1), branch: Regexp.last_match(2), require: false }].compact
  elsif place_or_version =~ %r{\Afile:\/\/(.*)}
    ['>= 0', { path: File.expand_path(Regexp.last_match(1)), require: false }]
  else
    [place_or_version, { require: false }]
  end
end

def gem_type(place_or_version)
  if place_or_version =~ %r{\Agit[:@]}
    :git
  elsif !place_or_version.nil? && place_or_version.start_with?('file:')
    :file
  else
    :gem
  end
end
# avoid newer versions that do not support ruby 2.1 anymore
gem 'nokogiri', '1.7.2'

group :development do
  gem 'activesupport', '4.2.9'
  # TODO: Use gem instead of git. Section mapping is merged into master, but not yet released
  gem "github_changelog_generator", *location_for(ENV['GITHUB_CHANGELOG_GENERATOR_VERSION'] || 'git@github.com:hunner/github-changelog-generator#c72ab3f')
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
