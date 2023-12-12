source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

group :development do
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
  gem 'rubocop', '~> 1.48', require: false
  gem 'rubocop-performance', '~> 1.16', require: false
  gem 'rubocop-rspec', '~> 2.19', require: false
  gem 'simplecov-console'
end

group :acceptance do
  gem 'minitar-cli'
  gem 'rspec-xsd'
  gem 'serverspec'
end

group :acceptance_ci do
  gem 'puppetlabs_spec_helper', '~> 6.0', require: false
end
