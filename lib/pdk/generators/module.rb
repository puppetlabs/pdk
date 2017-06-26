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
        defaults = {
          'name'         => "#{Etc.getlogin}-#{opts[:name]}",
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
        questions = [
          {
            name:             'name',
            question:         _('What is your Puppet Forge username?'),
            help:             _('This will be used when uploading your module to the Forge. You can opt out of this at any time.'),
            required:         true,
            validate_pattern: %r{\A[a-z0-9]+\Z}i,
            validate_message: _('Forge usernames can only contain lowercase letters and numbers'),
            default:          metadata.data['author'],
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

        prompt = TTY::Prompt.new

        interview = PDK::CLI::Util::Interview.new(prompt)

        questions.reject! { |q| q[:name] == 'license' } if opts.key?(:license)

        interview.add_questions(questions)

        puts _(
          "\nWe need to create a metadata.json file for this module, so we're going to ask you %{count} quick questions.\n" \
          "If the question is not applicable to this module, just leave the answer blank.\n\n",
        ) % { count: interview.num_questions }

        answers = interview.run

        if answers.nil?
          puts _('Interview cancelled, aborting...')
          exit 0
        end

        answers['name'] = "#{answers['name']}-#{opts[:name]}"
        metadata.update!(answers)

        puts '-' * 40
        puts _('SUMMARY')
        puts '-' * 40
        puts metadata.to_json
        puts '-' * 40
        puts

        unless prompt.yes?(_('About to generate this module; continue?')) # rubocop:disable Style/GuardClause
          puts _('Aborting...')
          exit 0
        end
      end
    end
  end
end
