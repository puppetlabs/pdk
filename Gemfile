source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

gem 'nokogiri', '~> 1.10.8'

group :development do
  gem 'activesupport', '4.2.9'
  gem 'github_changelog_generator', '~> 1.14'
  gem 'pry-byebug', '~> 3.4'
  gem 'ruby-prof'
  gem 'yard'
end

group :test do
  gem 'codecov'
  gem 'json', '~> 2.2.0'
  gem 'license_finder', '~> 6.1.2'
  gem 'parallel', '= 1.13.0'
  gem 'parallel_tests', '~> 2.24.0'
  gem 'parser', '~> 2.7.1'
  gem 'rake', '~> 12.3', '>= 12.3.3'
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

group :acceptance_ci do
  gem 'puppet_litmus'
  gem 'puppetlabs_spec_helper'
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
