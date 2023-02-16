require 'pdk/cli/util'
require 'pdk/validate'
require 'pdk/util/bundler'
require 'pdk/cli/util/interview'
require 'pdk/util/changelog_generator'
require 'pdk/module/build'

module PDK::CLI
  @release_cmd = @base_cmd.define_command do
    name 'release'
    usage 'release [options]'
    summary '(Experimental) Release a module to the Puppet Forge.'

    flag nil, :force,                'Release the module automatically, with no prompts.'
    flag nil, :'skip-validation',    'Skips the module validation check.'
    flag nil, :'skip-changelog',     'Skips the automatic changelog generation.'
    flag nil, :'skip-dependency',    'Skips the module dependency check.'
    flag nil, :'skip-documentation', 'Skips the documentation update.'
    flag nil, :'skip-build',         'Skips module build.'
    flag nil, :'skip-publish',       'Skips publishing the module to the forge.'

    option nil, :'forge-upload-url', 'Set forge upload url path.',
           argument: :required, default: 'https://forgeapi.puppetlabs.com/v3/releases'

    option nil, :'forge-token', 'Set Forge API token.',
           argument: :optional

    option nil, :version, 'Update the module to the specified version prior to release. When not specified, the new version will be computed from the Changelog where possible.',
           argument: :required

    option nil, :file, 'Path to the built module to push to the Forge. This option can only be used when --skip-build is also used. Defaults to pkg/<module version>.tar.gz',
           argument: :required

    run do |opts, _args, _cmd|
      # Make sure build is being run in a valid module directory with a metadata.json
      PDK::CLI::Util.ensure_in_module!(
        message:   '`pdk release` can only be run from inside a valid module with a metadata.json.',
        log_level: :info,
      )

      Release.prepare_interview(opts) unless opts[:force]

      Release.send_analytics('release', opts)

      release = PDK::Module::Release.new(nil, opts)

      Release.module_compatibility_checks!(release, opts)

      release.run
    end
  end

  module Release
    # Checks whether the module is compatible with PDK release process
    # @param release PDK::Module::Release Object representing the release
    # @param opts Options Hash from Cri
    def self.module_compatibility_checks!(release, opts)
      unless release.module_metadata.forge_ready?
        if opts[:force]
          PDK.logger.warn "This module is missing the following fields in the metadata.json: #{release.module_metadata.missing_fields.join(', ')}. " \
                          'These missing fields may affect the visibility of the module on the Forge.'
        else
          release.module_metadata.interview_for_forge!
          release.write_module_metadata!
        end
      end

      unless release.pdk_compatible? # rubocop:disable Style/GuardClause Nope!
        if opts[:force]
          PDK.logger.warn 'This module is not compatible with PDK, so PDK can not validate or test this build.'
        else
          PDK.logger.info 'This module is not compatible with PDK, so PDK can not validate or test this build. ' \
                          'Unvalidated modules may have errors when uploading to the Forge. ' \
                          'To make this module PDK compatible and use validate features, cancel the build and run `pdk convert`.'
          unless PDK::CLI::Util.prompt_for_yes('Continue build without converting?')
            PDK.logger.info 'Build cancelled; exiting.'
            PDK::Util.exit_process(1)
          end
        end
      end
    end

    # Send_analytics for the given command and Cri options
    def self.send_analytics(command, opts)
      # Don't pass tokens to analytics
      PDK::CLI::Util.analytics_screen_view(command, opts.reject { |k, _| k == :'forge-token' })
    end

    def self.prepare_interview(opts)
      questions = []

      unless opts[:'skip-validation']
        questions << {
          name:     'validation',
          question: 'Do you want to run the module validation ?',
          type:     :yes,
        }
      end
      unless opts[:'skip-changelog']
        questions << {
          name:     'changelog',
          question: 'Do you want to run the automatic changelog generation ?',
          type:     :yes,
        }
      end
      unless opts[:version]
        questions << {
          name:     'setversion',
          question: 'Do you want to set the module version ?',
          type:     :yes,
        }
      end
      unless opts[:'skip-dependency']
        questions << {
          name:     'dependency',
          question: 'Do you want to run the dependency-checker on this module?',
          type:     :yes,
        }
      end
      unless opts[:'skip-documentation']
        questions << {
          name:     'documentation',
          question: 'Do you want to update the documentation for this module?',
          type:     :yes,
        }
      end
      unless opts[:'skip-publish']
        questions << {
          name:     'publish',
          question: 'Do you want to publish the module on the Puppet Forge?',
          type:     :yes,
        }
      end

      prompt = TTY::Prompt.new(help_color: :cyan)
      interview = PDK::CLI::Util::Interview.new(prompt)
      interview.add_questions(questions)
      answers = interview.run

      unless answers.nil?
        opts[:'skip-validation'] = !answers['validation']
        opts[:'skip-changelog'] = !answers['changelog']
        opts[:'skip-dependency'] = !answers['dependency']
        opts[:'skip-documentation'] = !answers['documentation']
        opts[:'skip-publish'] = !answers['publish']

        prepare_version_interview(prompt, opts) if answers['setversion']

        prepare_publish_interview(prompt, opts) if answers['publish']
      end
      answers
    end

    def self.prepare_version_interview(prompt, opts)
      questions = [
        {
          name:             'version',
          question:         'Please set the module version',
          help:             'This value is the version that will be used in the changelog generator and building of the module.',
          required:         true,
          validate_pattern: %r{(\*|\d+(\.\d+){0,2}(\.\*)?)$}i,
          validate_message: 'The version format should be in the format x.y.z where x represents the major version, y the minor version and z the build number.',
        },
      ]
      interview = PDK::CLI::Util::Interview.new(prompt)
      interview.add_questions(questions)
      ver_answer = interview.run
      opts[:version] = ver_answer['version']
    end

    def self.prepare_publish_interview(prompt, opts)
      return if opts[:'forge-token']
      questions = [
        {
          name:             'apikey',
          question:         'Please set the api key(authorization token) to upload on the Puppet Forge',
          help:             'This value is used for authentication on the Puppet Forge to upload your module tarball.',
          required:         true,
        },
      ]
      interview = PDK::CLI::Util::Interview.new(prompt)
      interview.add_questions(questions)
      api_answer = interview.run
      opts[:'forge-token'] = api_answer['apikey']
    end
  end
end

require 'pdk/cli/release/prep'
require 'pdk/cli/release/publish'
