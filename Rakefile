require "bundler/gem_tasks"
require "rspec/core/rake_task"

gettext_spec = Gem::Specification.find_by_name 'gettext-setup'
load "#{gettext_spec.gem_dir}/lib/tasks/gettext.rake"
GettextSetup.initialize(File.absolute_path('locales', File.dirname(__FILE__)))

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/spec_helper_acceptance.rb,spec/acceptance/**'
end

desc 'Run acceptance tests'
RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = 'spec/spec_helper_acceptance.rb,spec/acceptance/**.rb'
end

task :default => :spec
