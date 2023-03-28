require 'bundler/gem_tasks'
require 'puppet_litmus/rake_tasks' if Bundler.rubygems.find_name('puppet_litmus').any?
# require 'puppetlabs_spec_helper/tasks/fixtures' if Bundler.rubygems.find_name('puppetlabs_spec_helper').any?
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

build_defs_file = 'ext/build_defaults.yaml'
if File.exist?(build_defs_file)
  begin
    require 'yaml'
    @build_defaults ||= YAML.load_file(build_defs_file)
  rescue StandardError => e
    $stderr.puts "Unable to load yaml from #{build_defs_file}:"
    $stderr.puts e
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

namespace :spec do
  desc 'Run RSpec code examples with coverage collection'
  task :coverage do
    ENV['COVERAGE'] = 'yes'
    Rake::Task['spec'].execute
  end
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/spec_helper_acceptance.rb,spec/acceptance/**'
end

namespace :acceptance do
  desc 'Run acceptance tests against current code'
  RSpec::Core::RakeTask.new(:local) do |t|
    t.rspec_opts = '--tag ~package' # Exclude package specific examples
    t.pattern = 'spec/acceptance/**/*_spec.rb'
  end
  task local: [:binstubs]

  task local_parallel: [:binstubs] do
    require 'parallel_tests'

    specs = Rake::FileList['spec/acceptance/**/*_spec.rb'].to_a
    ParallelTests::CLI.new.run(['-t', 'rspec'] + specs)
  end

  desc 'Run acceptance smoke tests against current code'
  RSpec::Core::RakeTask.new(:smoke) do |t|
    t.rspec_opts = '--tag ~package' # Exclude package specific examples
    # We only need to run a subset of the acceptance suite.
    t.pattern = 'spec/acceptance/bundle_spec.rb'
  end
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['-D', '-S', '-E']
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
    config.header = "# Changelog\n\n" \
                    "All changes to this repo will be documented in this file.\n" \
                    "See the [release notes](https://puppet.com/docs/pdk/latest/release_notes.html) for a high-level summary.\n"
    config.include_labels = ['enhancement', 'bug']
    config.user = 'puppetlabs'
    config.project = 'pdk'
    config.issues = false
  end
rescue LoadError
  desc 'Install github_changelog_generator to get access to automatic changelog generation'
  task :changelog do
    raise 'Install github_changelog_generator to get access to automatic changelog generation'
  end
end

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
  end
rescue LoadError
  desc :yard do
    raise 'Install yard to generate YARD documentation'
  end
end
