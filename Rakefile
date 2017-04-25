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
  require 'beaker-hostgenerator'

  test_target = ENV['TEST_TARGET']
  if test_target then
    puts "Generating beaker hosts using TEST_TARGET value #{test_target}"
    cli = BeakerHostGenerator::CLI.new(["#{test_target}{type=foss}", '--disable-default-role'])
    ENV['BEAKER_setfile'] = generated_hosts_filename = 'acceptance_hosts.yml'
    File.open(generated_hosts_filename, 'w') do |hosts_file|
      hosts_file.print(cli.execute)
    end
    
  else
    puts 'No TEST_TARGET set, falling back to regular beaker config'
  end

  t.pattern = 'spec/spec_helper_acceptance.rb,spec/acceptance/**.rb'
end

task :default => :spec
