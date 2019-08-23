source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

if RUBY_VERSION < '2.3.0'
  # avoid newer versions that do not support ruby 2.1 anymore
  gem 'cri', '>= 2.10.1', '< 2.11.0'
  gem 'nokogiri', '1.7.2'
else
  gem 'nokogiri', '~> 1.10.4' # rubocop:disable Bundler/DuplicatedGem
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
  gem 'parallel', '= 1.13.0'
  gem 'parser', '~> 2.5.1.2'
  gem 'rake', '~> 10.0'
  gem 'rspec', '~> 3.0'
  gem 'rspec-xsd'
  gem 'rubocop', '~> 0.57.2'
  gem 'rubocop-rspec', '~> 1.27.0'
  gem 'simplecov-console'
end

group :acceptance do
  gem 'minitar-cli'
  gem 'serverspec'
end

# Evaluate Gemfile.local and ~/.gemfile if they exist
extra_gemfiles = [
  "#{__FILE__}.local",
  File.join(Dir.home, '.gemfile'),
]

extra_gemfiles.each do |gemfile|
  if File.file?(gemfile) && File.readable?(gemfile)
    eval(File.read(gemfile), binding) # rubocop:disable Security/Eval
  end
end
