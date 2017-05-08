require 'etc'
require 'pathname'
require 'fileutils'

require 'pdk'
require 'pdk/logger'
require 'pdk/module/metadata'
require 'pdk/module/templatedir'
require 'pdk/cli/exec'
require 'pdk/cli/input'
require 'pdk/util'

module PDK
  module Generate
    class Module
      DEFAULT_TEMPLATE = 'https://github.com/puppetlabs/pdk-module-template'

      def self.invoke(opts={})
        defaults = {
          'version'      => '0.1.0',
          'dependencies' => [
            { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' }
          ]
        }

        defaults['license'] = opts[:license] if opts.has_key? :license
        target_dir = File.expand_path(opts[:target_dir])

        if File.exists?(target_dir)
          raise PDK::CLI::FatalError, _("The destination directory '%{dir}' already exists") % {:dir => target_dir}
        end

        metadata = PDK::Module::Metadata.new(defaults)

        module_interview(metadata, opts) unless opts[:'skip-interview'] # @todo Build way to get info by answers file

        temp_target_dir = PDK::Util.make_tmpdir_name('pdk-module-target')

        prepare_module_directory(temp_target_dir)

        template_url = opts.fetch(:'template-url', DEFAULT_TEMPLATE)

        PDK::Module::TemplateDir.new(template_url).with_templates do |templates|
          templates.render do |file_path, file_content|
            file = Pathname.new(temp_target_dir) + file_path
            file.dirname.mkpath
            file.write(file_content)
          end

          # Add information about the template used to generate the module to the
          # metadata (for a future update command).
          metadata.update!(templates.metadata)

          File.open(File.join(temp_target_dir, 'metadata.json'), 'w') do |metadata_file|
            metadata_file.puts metadata.to_json
          end
        end

        FileUtils.mv(temp_target_dir, target_dir)
      end

      def self.prepare_module_directory(target_dir)
        [
          File.join(target_dir, 'manifests'),
          File.join(target_dir, 'templates'),
        ].each do |dir|
          begin
            FileUtils.mkdir_p(dir)
          rescue SystemCallError
            raise PDK::CLI::FatalError, _("Unable to create directory '%{dir}'") % {:dir => dir}
          end
        end
      end

      def self.module_interview(metadata, opts={})
        puts _(
          "We need to create a metadata.json file for this module. Please answer the " +
          "following questions; if the question is not applicable to this module, feel free " +
          "to leave it blank."
        )

        begin
          system_user = Etc.getlogin
          puts "\n" + _("What is your Puppet Forge username?  [%{username}]") % {:username => system_user}
          metadata.update!('name' => "#{PDK::CLI::Input.get(system_user)}-#{opts[:name]}")
        rescue StandardError => e
          PDK.logger.error(_("We're sorry, we could not parse your module name: %{message}") % {:message => e.message})
          retry
        end

        begin
          puts "\n" + _("Puppet uses Semantic Versioning (semver.org) to version modules.")
          puts _("What version is this module? [%{default_version}]") % {default_version: metadata.data['version']}
          metadata.update!('version' => PDK::CLI::Input.get(metadata.data['version']))
        rescue StandardError => e
          PDK.logger.error(_("We're sorry, we could not parse that as a Semantic Version: %{message}") % {message: e.message})
          retry
        end

        puts "\n" + _("Who wrote this module? [%{default_author}]") % {default_author: metadata.data['author']}
        metadata.update!('author' => PDK::CLI::Input.get(metadata.data['author']))

        if not opts.has_key? :license
          puts "\n" + _("What license does this module code fall under? [%{default_license}]") % {default_license: metadata.data['license']}
          metadata.update!('license' => PDK::CLI::Input.get(metadata.data['license']))
        end

        puts "\n" + _("How would you describe this module in a single sentence?")
        metadata.update!('summary' => PDK::CLI::Input.get(metadata.data['summary']))

        puts "\n" + _("Where is this module's source code repository?")
        metadata.update!('source' => PDK::CLI::Input.get(metadata.data['source']))

        puts "\n" + _("Where can others go to learn more about this module? [%{default_project_page}]") % {default_project_page: (metadata.data['project_page'] || '(none)')}
        metadata.update!('project_page' => PDK::CLI::Input.get(metadata.data['project_page']))

        puts "\n" + _("Where can others go to file issues about this module? [%{default_issues_url}]") % {default_issues_url: (metadata.data['issues_url'] || '(none)')}
        metadata.update!('issues_url' => PDK::CLI::Input.get(metadata.data['issues_url']))

        puts
        puts '-' * 40
        puts metadata.to_json
        puts '-' * 40
        puts
        puts _("About to generate this metadata; continue? [n/Y]")

        if PDK::CLI::Input.get('Y') !~ /^y(es)?$/i
          puts _("Aborting...")
          exit 0
        end
      end
    end
  end
end
