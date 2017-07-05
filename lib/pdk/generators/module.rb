require 'etc'
require 'pathname'
require 'fileutils'
require 'tty-prompt'

require 'pdk'
require 'pdk/logger'
require 'pdk/module/metadata'
require 'pdk/module/templatedir'
require 'pdk/cli/exec'
require 'pdk/cli/util/interview'
require 'pdk/util'
require 'pdk/util/version'

module PDK
  module Generate
    class Module
      DEFAULT_TEMPLATE = 'https://github.com/puppetlabs/pdk-module-template'.freeze

      def self.invoke(opts = {})
        target_dir = File.expand_path(opts[:target_dir])

        if File.exist?(target_dir)
          raise PDK::CLI::FatalError, _("The destination directory '%{dir}' already exists") % { dir: target_dir }
        end

        parent_dir = File.dirname(target_dir)

        begin
          test_file = File.join(parent_dir, '.pdk-test-writable')
          File.open(test_file, 'w') { |f| f.write('This file was created by the Puppet Development Kit to test if this folder was writable, you can safely remove this file.') }
          FileUtils.rm_f(test_file)
        rescue Errno::EACCES
          raise PDK::CLI::FatalError, _("You do not have permission to write to '%{parent_dir}'") % {
            parent_dir: parent_dir,
          }
        end

        metadata = prepare_metadata(opts)

        temp_target_dir = PDK::Util.make_tmpdir_name('pdk-module-target')

        prepare_module_directory(temp_target_dir)

        template_url = opts.fetch(:'template-url', PDK.answers['template-url'] || DEFAULT_TEMPLATE)

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

        PDK.answers.update!('template-url' => template_url)

        begin
          FileUtils.mv(temp_target_dir, target_dir)
        rescue Errno::EACCES => e
          raise PDK::CLI::FatalError, _("Failed to move '%{source}' to '%{target}': %{message}") % {
            source:  temp_target_dir,
            target:  target_dir,
            message: e.message,
          }
        end
      end

      def self.username_from_login
        login = Etc.getlogin || ''
        login_clean = login.gsub(%r{[^0-9a-z]}i, '')
        login_clean = 'username' if login_clean.empty?

        if login_clean != login
          PDK.logger.warn _('Your username is not a valid Forge username, proceeding with the username %{username}. You can fix this afterwards in metadata.json.') % {
            username: login_clean,
          }
        end

        login_clean
      end

      def self.prepare_metadata(opts)
        username = PDK.answers['forge-username'] || username_from_login

        defaults = {
          'name'         => "#{username}-#{opts[:name]}",
          'version'      => '0.1.0',
          'dependencies' => [
            { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 4.13.1 < 5.0.0' },
          ],
        }
        defaults['author'] = PDK.answers['author'] unless PDK.answers['author'].nil?
        defaults['license'] = PDK.answers['license'] unless PDK.answers['license'].nil?
        defaults['license'] = opts[:license] if opts.key? :license

        metadata = PDK::Module::Metadata.new(defaults)

        module_interview(metadata, opts) unless opts[:'skip-interview']

        metadata.update!('pdk-version' => PDK::Util::Version.version_string)

        metadata
      end

      def self.prepare_module_directory(target_dir)
        [
          File.join(target_dir, 'manifests'),
          File.join(target_dir, 'templates'),
        ].each do |dir|
          begin
            FileUtils.mkdir_p(dir)
          rescue SystemCallError => e
            raise PDK::CLI::FatalError, _("Unable to create directory '%{dir}': %{message}") % {
              dir:     dir,
              message: e.message,
            }
          end
        end
      end

      def self.module_interview(metadata, opts = {})
        questions = [
          {
            name:             'name',
            question:         _('What is your Puppet Forge username?'),
            help:             _('This will be used when uploading your module to the Forge. You can opt out of this at any time.'),
            required:         true,
            validate_pattern: %r{\A[a-z0-9]+\Z}i,
            validate_message: _('Forge usernames can only contain lowercase letters and numbers'),
            default:          PDK.answers['forge-username'] || metadata.data['author'],
          },
          {
            name:             'version',
            question:         _('What version is this module?'),
            help:             _('Puppet uses Semantic Versioning (semver.org) to version modules.'),
            required:         true,
            validate_pattern: %r{\A[0-9]+\.[0-9]+\.[0-9]+},
            validate_message: _('Semantic Version numbers must be in the form MAJOR.MINOR.PATCH'),
            default:          metadata.data['version'],
          },
          {
            name:     'author',
            question: _('Who wrote this module?'),
            help:     _('The person who gets credit for creating the module. '),
            required: true,
            default:  metadata.data['author'],
          },
          {
            name:     'license',
            question: _('What license does this module code fall under?'),
            help:     _('This should be an identifier from https://spdk.org/licenses/. Common values are "Apache-2.0", "MIT", or "proprietary".'),
            required: true,
            default:  metadata.data['license'],
          },
          {
            name:     'summary',
            question: _('How would you describe this module in a single sentence?'),
            help:     _('To help other Puppet users understand what the module does.'),
            required: true,
            default:  metadata.data['summary'],
          },
          {
            name:     'source',
            question: _("Where is this modules's source code repository?"),
            help:     _('Usually a GitHub URL'),
            required: true,
            default:  metadata.data['source'],
          },
          {
            name:     'project_page',
            question: _('Where can others go to learn more about this module?'),
            help:     _('A web site that offers full information about your module.'),
            default:  metadata.data['project_page'],
          },
          {
            name:     'issues_url',
            question: _('Where can others go to file issues about this module?'),
            help:     _('A web site with a public bug tracker for your module.'),
            default:  metadata.data['issues_url'],
          },
        ]

        prompt = TTY::Prompt.new(help_color: :cyan)

        interview = PDK::CLI::Util::Interview.new(prompt)

        questions.reject! { |q| q[:name] == 'license' } if opts.key?(:license)

        interview.add_questions(questions)

        puts _(
          "\nWe need to create a metadata.json file for this module, so we're going to ask you %{count} quick questions.\n" \
          "If the question is not applicable to this module, just leave the answer blank.\n\n",
        ) % { count: interview.num_questions }

        answers = interview.run

        if answers.nil?
          PDK.logger.info _('Interview cancelled, not generating the module.')
          exit 0
        end

        forge_username = answers['name']
        answers['name'] = "#{answers['name']}-#{opts[:name]}"
        answers['license'] = opts[:license] if opts.key?(:license)
        metadata.update!(answers)

        puts '-' * 40
        puts _('SUMMARY')
        puts '-' * 40
        puts metadata.to_json
        puts '-' * 40
        puts

        unless prompt.yes?(_('About to generate this module; continue?'))
          PDK.logger.info _('Module not generated.')
          exit 0
        end

        PDK.answers.update!(
          'forge-username' => forge_username,
          'author'         => answers['author'],
          'license'        => answers['license'],
        )
      end
    end
  end
end
