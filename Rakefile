require "bundler/gem_tasks"
require "rspec/core/rake_task"

gettext_spec = Gem::Specification.find_by_name 'gettext-setup'
load "#{gettext_spec.gem_dir}/lib/tasks/gettext.rake"
GettextSetup.initialize(File.absolute_path('locales', File.dirname(__FILE__)))

build_defs_file = 'ext/build_defaults.yaml'
if File.exist?(build_defs_file)
  begin
    require 'yaml'
    @build_defaults ||= YAML.load_file(build_defs_file)
  rescue Exception => e
    STDERR.puts "Unable to load yaml from #{build_defs_file}:"
    STDERR.puts e
  end
  @packaging_url  = @build_defaults['packaging_url']
  @packaging_repo = @build_defaults['packaging_repo']
  raise "Could not find packaging url in #{build_defs_file}" if @packaging_url.nil?
  raise "Could not find packaging repo in #{build_defs_file}" if @packaging_repo.nil?

  namespace :package do
    desc "Bootstrap packaging automation (clone packaging repo)"
    task :bootstrap do
      if File.exist?("ext/#{@packaging_repo}")
        puts "It looks like you already have ext/#{@packaging_repo}. If you don't like it, blow it away with package:implode."
      else
        cd 'ext' do
          %x{git clone #{@packaging_url}}
        end
      end
    end
    desc "Remove all cloned packaging automation"
    task :implode do
      rm_rf "ext/#{@packaging_repo}"
    end
  end
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/spec_helper_acceptance.rb,spec/acceptance/**'
end

namespace :acceptance do

  desc 'Run acceptance tests against a puppet-sdk package'
  RSpec::Core::RakeTask.new(:package) do |t|
    require 'beaker-hostgenerator'

    ENV['BEAKER_TESTMODE'] = 'agent'

    unless ENV['SHA'] then
      abort 'Environment variable SHA must be set to the SHA or tag of a puppet-sdk build'
    end

    test_target = ENV['TEST_TARGET']
    if test_target then
      unless ENV['BUILD_SERVER'] || test_target !~ /win/
        abort 'Testing against Windows requires environment variable BUILD_SERVER '\
              'to be set to the hostname of your build server (JIRA BKR-1109)'
      end
      puts "Generating beaker hosts using TEST_TARGET value #{test_target}"
      cli = BeakerHostGenerator::CLI.new(["#{test_target}{type=foss}", '--disable-default-role'])
      ENV['BEAKER_setfile'] = generated_hosts_filename = 'acceptance_hosts.yml'
      File.open(generated_hosts_filename, 'w') do |hosts_file|
        hosts_file.print(cli.execute)
      end
    
    else
      puts 'No TEST_TARGET set, falling back to regular beaker config'
    end

    t.pattern = 'spec/acceptance/**.rb'
  end

  desc 'Run acceptance tests against current code'
  RSpec::Core::RakeTask.new(:local) do |t|
    ENV['BEAKER_TESTMODE'] = 'local'

    # Set beaker to not attempt to allocate or provision any host
    # See bug QA-2991 - beaker-testmode_switcher should do this automatically
    ENV['BEAKER_setfile'] = 'spec/acceptance/nodesets/none.yml'
    ENV['BEAKER_provision'] = 'no'

    t.pattern = 'spec/acceptance/**.rb'
  end
end

desc 'run static analysis with rubocop'
task(:rubocop) do
  require 'rubocop'
  cli = RuboCop::CLI.new
  exit_code = cli.run(%w(--display-cop-names --format simple))
  raise "RuboCop detected offenses" if exit_code != 0
end

task :default => :spec
