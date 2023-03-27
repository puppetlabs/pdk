source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

group :development do
  gem 'github_changelog_generator', '~> 1.15.2'
  gem 'ruby-prof'
  gem 'yard'

  gem 'fuubar'
  gem 'pry'
  gem 'pry-stack_explorer'
end

group :test do
  gem 'codecov'
  gem 'parallel'
  gem 'parallel_tests'
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 1.28.0', require: false
  gem 'rubocop-performance', '~> 1.9.1', require: false
  gem 'rubocop-rspec', '~> 2.0.1', require: false
  gem 'simplecov-console'
end

group :acceptance do
  gem 'minitar-cli'
  gem 'rspec-xsd'
  gem 'serverspec'
end

group :acceptance_ci do
  gem 'puppetlabs_spec_helper'
end

# Evaluate Gemfile.local and ~/.gemfile if they exist
extra_gemfiles = [
  "#{__FILE__}.local",
  File.join(Dir.home, '.gemfile'),
]

extra_gemfiles.each do |gemfile|
  eval(File.read(gemfile), binding) if File.file?(gemfile) && File.readable?(gemfile)
end
