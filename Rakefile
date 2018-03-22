# frozen_string_literal: true

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

namespace :gettext do
  desc 'Remove obsolete messages from translations'
  task(:clean_obsolete, [:language]) do |_task, args|
    file_name = File.join(File.dirname(__FILE__), 'locales', args[:language], 'pdk.po')
    success = system("msgattrib --no-obsolete #{file_name} -o #{file_name}")

    puts "Updated #{file_name}" if success
  end

  desc 'Remove fuzzy messages from translations (should only be used by translators of this language)'
  task(:clean_fuzzy, [:language]) do |_task, args|
    file_name = File.join(File.dirname(__FILE__), 'locales', args[:language], 'pdk.po')
    success = system("msgattrib --clear-fuzzy #{file_name} -o #{file_name}")

    puts "Updated #{file_name}" if success
  end
end

begin
  require 'github_changelog_generator/task'
  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    require 'pdk/version'
    config.future_release = "v#{PDK::VERSION}"
    config.header = "# Changelog\n\n" \
      "All changes to this repo will be documented in this file.\n" \
      "See the [release notes](https://puppet.com/docs/pdk/latest/release_notes.html) for a high-level summary.\n"
    config.include_labels = %w[enhancement bug]
    config.user = 'puppetlabs'
    config.project = 'pdk'
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

desc 'Check for unapproved licenses in dependencies'
task(:license_finder) do
  system('license_finder --decisions-file=.dependency_decisions.yml') || raise(StandardError, 'Unapproved license(s) found on dependencies')
end
