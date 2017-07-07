require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

gettext_spec = Gem::Specification.find_by_name 'gettext-setup'
load "#{gettext_spec.gem_dir}/lib/tasks/gettext.rake"
GettextSetup.initialize(File.absolute_path('locales', File.dirname(__FILE__)))

build_defs_file = 'ext/build_defaults.yaml'
if File.exist?(build_defs_file)
  begin
    require 'yaml'
    @build_defaults ||= YAML.load_file(build_defs_file)
  rescue StandardError => e
    STDERR.puts "Unable to load yaml from #{build_defs_file}:"
    STDERR.puts e
  end
  @packaging_url  = @build_defaults['packaging_url']
  @packaging_repo = @build_defaults['packaging_repo']
  raise "Could not find packaging url in #{build_defs_file}" if @packaging_url.nil?
  raise "Could not find packaging repo in #{build_defs_file}" if @packaging_repo.nil?

  namespace :package do
    desc 'Bootstrap packaging automation (clone packaging repo)'
    task :bootstrap do
      if File.exist?("ext/#{@packaging_repo}")
        puts "It looks like you already have ext/#{@packaging_repo}. If you don't like it, blow it away with package:implode."
      else
        cd 'ext' do
          `git clone #{@packaging_url}`
        end
      end
    end
    desc 'Remove all cloned packaging automation'
    task :implode do
      rm_rf "ext/#{@packaging_repo}"
    end
  end
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/spec_helper_acceptance.rb,spec/acceptance/**'
end

namespace :acceptance do
  desc 'Run acceptance tests against a pdk package'
  task(:package) do
    require 'beaker-hostgenerator'

    unless ENV['SHA']
      abort 'Environment variable SHA must be set to the SHA or tag of a pdk build'
    end

    test_target = ENV['TEST_TARGET']
    if test_target
      unless ENV['BUILD_SERVER'] || test_target !~ %r{win}
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

    sh('bundle exec beaker -h acceptance_hosts.yml --options-file package-testing/config/options.rb --tests package-testing/tests/')
  end

  desc 'Run acceptance tests against current code'
  RSpec::Core::RakeTask.new(:local) do |t|
    t.pattern = 'spec/acceptance/**.rb'
  end
  task local: [:binstubs]
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = %w[-D -S -E]
end

task(:binstubs) do
  system('bundle binstubs pdk --force')
end

task default: :spec

begin
  require 'github_changelog_generator/task'
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    require 'pdk/version'
    config.future_release = "v#{PDK::VERSION}"
    config.header = "# Changelog\n\nAll notable changes to this project will be documented in this file.\n"
    config.include_labels = %w[enhancement bug]
    config.user = 'puppetlabs'
  end
rescue LoadError
  desc 'Install github_changelog_generator to get access to automatic changelog generation'
  task :changelog do
    raise 'Install github_changelog_generator to get access to automatic changelog generation'
  end
end
