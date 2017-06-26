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
require 'pdk/util/version'

module PDK
  module Generate
    class Module
      DEFAULT_TEMPLATE = 'https://github.com/puppetlabs/pdk-module-template'.freeze

      def self.invoke(opts = {})
        username = Etc.getlogin
        if username != username.gsub(%r{[^0-9a-z]}i, '')
          raise PDK::CLI::FatalError, _('Unable to select a valid Forge username, run without --skip-interview to enter one') if opts[:'skip-interview']

          username = ''
        end

        defaults = {
          'name'         => "#{username}-#{opts[:name]}",
          'version'      => '0.1.0',
          'dependencies' => [
            { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 4.13.1 < 5.0.0' },
          ],
        }

        defaults['license'] = opts[:license] if opts.key? :license
        target_dir = File.expand_path(opts[:target_dir])

        if File.exist?(target_dir)
          raise PDK::CLI::FatalError, _("The destination directory '%{dir}' already exists") % { dir: target_dir }
        end

        metadata = PDK::Module::Metadata.new(defaults)

        module_interview(metadata, opts) unless opts[:'skip-interview'] # @todo Build way to get info by answers file

        metadata.update!('pdk-version' => PDK::Util::Version.version_string)

        temp_target_dir = PDK::Util.make_tmpdir_name('pdk-module-target')

        prepare_module_directory(temp_target_dir)

        template_url = opts.fetch(:'template-url', DEFAULT_TEMPLATE)

        PDK::Module::TemplateDir.new(template_url) do |templates|
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
            raise PDK::CLI::FatalError, _("Unable to create directory '%{dir}'") % { dir: dir }
          end
        end
      end

      def self.module_interview(metadata, opts = {})
        puts _(
          'We need to create a metadata.json file for this module. Please answer the ' \
          'following questions; if the question is not applicable to this module, feel free ' \
          'to leave it blank.',
        )

        begin
          puts ''
          forge_user = PDK::CLI::Input.get(_('What is your Puppet Forge username?'), metadata.data['author'])
          metadata.update!('name' => "#{forge_user}-#{opts[:name]}")
        rescue StandardError => e
          PDK.logger.error(_("We're sorry, we could not parse your module name: %{message}") % { message: e.message })
          retry
        end

        begin
          puts "\n" + _('Puppet uses Semantic Versioning (semver.org) to version modules.')
          module_version = PDK::CLI::Input.get(_('What version is this module?'), metadata.data['version'])
          metadata.update!('version' => module_version)
        rescue StandardError => e
          PDK.logger.error(_("We're sorry, we could not parse that as a Semantic Version: %{message}") % { message: e.message })
          retry
        end

        puts ''
        module_author = PDK::CLI::Input.get(_('Who wrote this module?'), metadata.data['author'])
        metadata.update!('author' => module_author)

        unless opts.key?(:license)
          puts ''
          module_license = PDK::CLI::Input.get(_('What license does this module code fall under?'), metadata.data['license'])
          metadata.update!('license' => module_license)
        end

        puts ''
        module_summary = PDK::CLI::Input.get(_('How would you describe this module in a single sentence?'), metadata.data['summary'])
        metadata.update!('summary' => module_summary)

        puts ''
        module_source = PDK::CLI::Input.get(_("Where is this module's source code repository?"), metadata.data['source'])
        metadata.update!('source' => module_source)

        puts ''
        module_page = PDK::CLI::Input.get(_('Where can others go to learn more about this module?'), metadata.data['project_page'])
        metadata.update!('project_page' => module_page)

        puts ''
        module_issues = PDK::CLI::Input.get(_('Where can others go to file issues about this module?'), metadata.data['issues_url'])
        metadata.update!('issues_url' => module_issues)

        puts
        puts '-' * 40
        puts metadata.to_json
        puts '-' * 40
        puts

        unless PDK::CLI::Input.get(_('About to generate this module; continue?'), 'Y') =~ %r{^y(es)?$}i # rubocop:disable Style/GuardClause
          puts _('Aborting...')
          exit 0
        end
      end
    end
  end
end
