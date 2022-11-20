require 'pdk'

module PDK
  module Generate
    class Module
      def self.validate_options(opts)
        require 'pdk/cli/util/option_validator'

        unless PDK::CLI::Util::OptionValidator.valid_module_name?(opts[:module_name])
          error_msg = "'%{module_name}' is not a valid module name.\n" \
                      'Module names must begin with a lowercase letter and can only include lowercase letters, digits, and underscores.' % { module_name: opts[:module_name] }
          raise PDK::CLI::ExitWithError, error_msg
        end

        target_dir = PDK::Util::Filesystem.expand_path(opts[:target_dir])
        raise PDK::CLI::ExitWithError, "The destination directory '%{dir}' already exists" % { dir: target_dir } if PDK::Util::Filesystem.exist?(target_dir)
      end

      def self.invoke(opts = {})
        require 'pdk/util'
        require 'pdk/util/template_uri'
        require 'pathname'

        validate_options(opts) unless opts[:module_name].nil?

        metadata = prepare_metadata(opts)

        target_dir = PDK::Util::Filesystem.expand_path(opts[:target_dir] || opts[:module_name])
        parent_dir = File.dirname(target_dir)

        begin
          test_file = File.join(parent_dir, '.pdk-test-writable')
          PDK::Util::Filesystem.write_file(test_file, 'This file was created by the Puppet Development Kit to test if this folder was writable, you can safely remove this file.')
          PDK::Util::Filesystem.rm_f(test_file)
        rescue Errno::EACCES
          raise PDK::CLI::FatalError, "You do not have permission to write to '%{parent_dir}'" % {
            parent_dir: parent_dir,
          }
        end

        temp_target_dir = PDK::Util.make_tmpdir_name('pdk-module-target')

        prepare_module_directory(temp_target_dir)

        template_uri = PDK::Util::TemplateURI.new(opts)

        if template_uri.default? && template_uri.default_ref?
          PDK.logger.info 'Using the default template-url and template-ref.'
        else
          PDK.logger.info "Using the %{method} template-url and template-ref '%{template_uri}'." % {
            method: opts.key?(:'template-url') ? 'specified' : 'saved',
              template_uri: template_uri.metadata_format,
          }
        end

        begin
          context = PDK::Context::None.new(temp_target_dir)
          PDK::Template.with(template_uri, context) do |template_dir|
            template_dir.render_new_module(metadata.data['name'], metadata.data) do |relative_file_path, file_content, file_status|
              next if [:delete, :unmanage].include?(file_status)
              file = Pathname.new(temp_target_dir) + relative_file_path
              file.dirname.mkpath
              PDK::Util::Filesystem.write_file(file, file_content)
            end

            # Add information about the template used to generate the module to the
            # metadata (for a future update command).
            metadata.update!(template_dir.metadata)

            metadata.write!(File.join(temp_target_dir, 'metadata.json'))
          end
        rescue ArgumentError => e
          raise PDK::CLI::ExitWithError, e
        end

        # Only update the answers files after metadata has been written.
        require 'pdk/answer_file'
        if template_uri.default? && template_uri.default_ref?
          # If the user specifies our default template url via the command
          # line, remove the saved template-url answer so that the template_uri
          # resolution can find new default URLs in the future.
          PDK.config.set(%w[user module_defaults template-url], nil) if opts.key?(:'template-url')
        else
          # Save the template-url answers if the module was generated using a
          # template/reference other than ours.
          PDK.config.set(%w[user module_defaults template-url], template_uri.metadata_format)
        end

        begin
          if PDK::Util::Filesystem.mv(temp_target_dir, target_dir)
            unless opts[:'skip-bundle-install']
              Dir.chdir(target_dir) do
                require 'pdk/util/bundler'
                PDK::Util::Bundler.ensure_bundle!
              end
            end

            PDK.logger.info "Module '%{name}' generated at path '%{path}'." % {
              name: opts[:module_name],
              path: target_dir,
            }
            PDK.logger.info "In your module directory, add classes with the 'pdk new class' command."
          end
        rescue Errno::EACCES => e
          raise PDK::CLI::FatalError, "Failed to move '%{source}' to '%{target}': %{message}" % {
            source:  temp_target_dir,
            target:  target_dir,
            message: e.message,
          }
        end
      end

      def self.username_from_login
        require 'etc'

        login = Etc.getlogin || ''
        login_clean = login.downcase.gsub(%r{[^0-9a-z]}i, '')
        login_clean = 'username' if login_clean.empty?

        if login_clean != login
          PDK.logger.debug 'Your username is not a valid Forge username. Proceeding with the username %{username}. You can fix this later in metadata.json.' % {
            username: login_clean,
          }
        end

        login_clean
      end

      def self.prepare_metadata(opts = {})
        require 'pdk/answer_file'
        require 'pdk/module/metadata'

        opts[:username] = (opts[:username] || PDK.config.get_within_scopes('module_defaults.forge_username') || username_from_login).downcase

        defaults = PDK::Module::Metadata::DEFAULTS.dup

        defaults['name'] = "#{opts[:username]}-#{opts[:module_name]}" unless opts[:module_name].nil?
        PDK.config.with_scoped_value('module_defaults.author') { |val| defaults['author'] = val }
        PDK.config.with_scoped_value('module_defaults.license') { |val| defaults['license'] = val }
        defaults['license'] = opts[:license] if opts.key?(:license)

        metadata = PDK::Module::Metadata.new(defaults)
        module_interview(metadata, opts) unless opts[:'skip-interview']

        metadata
      end

      def self.prepare_module_directory(target_dir)
        [
          File.join(target_dir, 'examples'),
          File.join(target_dir, 'files'),
          File.join(target_dir, 'manifests'),
          File.join(target_dir, 'templates'),
          File.join(target_dir, 'tasks'),
        ].each do |dir|
          begin
            PDK::Util::Filesystem.mkdir_p(dir)
          rescue SystemCallError => e
            raise PDK::CLI::FatalError, "Unable to create directory '%{dir}': %{message}" % {
              dir:     dir,
              message: e.message,
            }
          end
        end
      end

      def self.module_interview(metadata, opts = {})
        require 'pdk/module/metadata'
        require 'pdk/cli/util/interview'

        questions = [
          {
            name:             'module_name',
            question:         'If you have a name for your module, add it here.',
            help:             'This is the name that will be associated with your module, it should be relevant to the modules content.',
            required:         true,
            validate_pattern: %r{\A[a-z][a-z0-9_]*\Z}i,
            validate_message: 'Module names must begin with a lowercase letter and can only include lowercase letters, numbers, and underscores.',
          },
          {
            name:             'forge_username',
            question:         'If you have a Puppet Forge username, add it here.',
            help:             'We can use this to upload your module to the Forge when it\'s complete.',
            required:         true,
            validate_pattern: %r{\A[a-z0-9]+\Z}i,
            validate_message: 'Forge usernames can only contain lowercase letters and numbers',
            default:          opts[:username],
          },
          {
            name:             'version',
            question:         'What version is this module?',
            help:             'Puppet uses Semantic Versioning (semver.org) to version modules.',
            required:         true,
            validate_pattern: %r{\A[0-9]+\.[0-9]+\.[0-9]+}i,
            validate_message: 'Semantic Version numbers must be in the form MAJOR.MINOR.PATCH',
            default:          metadata.data['version'],
            forge_only:       true,
          },
          {
            name:     'author',
            question: 'Who wrote this module?',
            help:     'This is used to credit the module\'s author.',
            required: true,
            default:  metadata.data['author'],
          },
          {
            name:     'license',
            question: 'What license does this module code fall under?',
            help:     'This should be an identifier from https://spdx.org/licenses/. Common values are "Apache-2.0", "MIT", or "proprietary".',
            required: true,
            default:  metadata.data['license'],
          },
          {
            name:     'operatingsystem_support',
            question: 'What operating systems does this module support?',
            help:     'Use the up and down keys to move between the choices, space to select and enter to continue.',
            required: true,
            type:     :multi_select,
            choices:  PDK::Module::Metadata::OPERATING_SYSTEMS,
            default:  PDK::Module::Metadata::DEFAULT_OPERATING_SYSTEMS.map do |os_name|
              # tty-prompt uses a 1-index
              PDK::Module::Metadata::OPERATING_SYSTEMS.keys.index(os_name) + 1
            end,
          },
          {
            name:       'summary',
            question:   'Summarize the purpose of this module in a single sentence.',
            help:       'This helps other Puppet users understand what the module does.',
            required:   true,
            default:    metadata.data['summary'],
            forge_only: true,
          },
          {
            name:       'source',
            question:   'If there is a source code repository for this module, enter the URL here.',
            help:       'Skip this if no repository exists yet. You can update this later in the metadata.json.',
            required:   true,
            default:    metadata.data['source'],
            forge_only: true,
          },
          {
            name:       'project_page',
            question:   'If there is a URL where others can learn more about this module, enter it here.',
            help:       'Optional. You can update this later in the metadata.json.',
            default:    metadata.data['project_page'],
            forge_only: true,
          },
          {
            name:       'issues_url',
            question:   'If there is a public issue tracker for this module, enter its URL here.',
            help:       'Optional. You can update this later in the metadata.json.',
            default:    metadata.data['issues_url'],
            forge_only: true,
          },
        ]

        prompt = TTY::Prompt.new(help_color: :cyan)

        interview = PDK::CLI::Util::Interview.new(prompt)

        if opts[:only_ask]
          questions.reject! do |question|
            if %w[module_name forge_username].include?(question[:name])
              metadata.data['name'] && metadata.data['name'] =~ %r{\A[a-z0-9]+-[a-z][a-z0-9_]*\Z}i
            else
              !opts[:only_ask].include?(question[:name])
            end
          end
        else
          questions.reject! { |q| q[:name] == 'module_name' } if opts.key?(:module_name)
          questions.reject! { |q| q[:name] == 'license' } if opts.key?(:license)
          questions.reject! { |q| q[:forge_only] } unless opts[:'full-interview']
        end

        interview.add_questions(questions)

        if PDK::Util::Filesystem.file?('metadata.json')
          puts "\nWe need to update the metadata.json file for this module, so we\'re going to ask you %{count} " \
               "questions.\n" % {
                 count: interview.num_questions,
               }
        else
          puts "\nWe need to create the metadata.json file for this module, so we\'re going to ask you %{count} " \
               "questions.\n" % {
                 count: interview.num_questions,
               }
        end

        puts 'If the question is not applicable to this module, accept the default option ' \
             'shown after each question. You can modify any answers at any time by manually updating ' \
             "the metadata.json file.\n\n"

        answers = interview.run

        if answers.nil?
          PDK.logger.info 'No answers given, interview cancelled.'
          exit 0
        end

        unless answers['forge_username'].nil?
          opts[:username] = answers['forge_username']

          unless answers['module_name'].nil?
            opts[:module_name] = answers['module_name']

            answers.delete('module_name')
          end

          answers['name'] = "#{opts[:username]}-" + (opts[:module_name])
          answers.delete('forge_username')
        end

        answers['license'] = opts[:license] if opts.key?(:license)
        answers['operatingsystem_support'].flatten! if answers.key?('operatingsystem_support')

        metadata.update!(answers)

        if opts[:prompt].nil? || opts[:prompt]
          require 'pdk/cli/util'

          continue = PDK::CLI::Util.prompt_for_yes(
            'Metadata will be generated based on this information, continue?',
            prompt:         prompt,
            cancel_message: 'Interview cancelled; exiting.',
          )

          unless continue
            PDK.logger.info 'Process cancelled; exiting.'
            exit 0
          end
        end

        require 'pdk/answer_file'
        PDK.config.set(%w[user module_defaults forge_username], opts[:username]) unless opts[:username].nil?
        PDK.config.set(%w[user module_defaults author], answers['author']) unless answers['author'].nil?
        PDK.config.set(%w[user module_defaults license], answers['license']) unless answers['license'].nil?
      end
    end
  end
end
