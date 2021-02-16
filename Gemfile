source 'https://rubygems.org'

# Specify your gem's dependencies in pdk.gemspec
gemspec

group :development do
  gem 'activesupport', '4.2.9'
  gem 'github_changelog_generator', '~> 1.14'
  gem 'pry-byebug', '~> 3.4'
  gem 'ruby-prof'
  gem 'yard'
end

group :test do
  gem 'coveralls'
  gem 'json', '~> 2.2.0'
  gem 'license_finder', '~> 5.4.1'
  gem 'parallel', '= 1.13.0'
  gem 'parallel_tests', '~> 2.24.0'
  gem 'rake', '~> 12.3', '>= 12.3.3'
  gem 'rspec', '~> 3.0'
  gem 'rspec-xsd'
  gem 'rubocop', '~> 1.6'
  gem 'rubocop-performance', '~> 1.9'
  gem 'rubocop-rspec', '~> 2.2'
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
