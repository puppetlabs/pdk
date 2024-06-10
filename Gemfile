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
  gem 'parallel'
  gem 'parallel_tests'
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 1.50.0', require: false
  gem 'rubocop-performance', '~> 1.16', require: false
  gem 'rubocop-rspec', '~> 2.19', require: false
  gem 'simplecov-console'

  # Temporary exclusion required as these versions are currently broken for us
  gem 'rubocop-factory_bot', '!= 2.26.0', require: false
  gem 'rubocop-rspec_rails', '!= 2.29.0', require: false
end

group :acceptance do
  gem 'minitar-cli'
  gem 'rspec-xsd'
  gem 'serverspec'
end

group :acceptance_ci do
  gem 'puppetlabs_spec_helper', '~> 7.0', require: false
end
