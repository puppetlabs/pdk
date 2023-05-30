require 'pdk/cli/util'
require 'pdk/validate'
require 'pdk/util/bundler'
require 'pdk/cli/util/interview'
require 'pdk/module/build'

module PDK
  module CLI
    @publish_cmd = @base_cmd.define_command do # rubocop:disable Metrics/BlockLength
      name 'publish'
      usage 'publish [options] <tarball>'
      summary 'Publishes the module to the Forge.'

      flag nil, :force,                'Publish the module automatically, with no prompts.'

      option nil, :'forge-upload-url', 'Set forge upload url path.',
             argument: :required, default: 'https://forgeapi.puppetlabs.com/v3/releases'

      option nil, :'forge-token', 'Set Forge API token (you may also set via environment variable PDK_FORGE_TOKEN)', argument: :required

      run do |opts, _args, _cmd|
        # Make sure build is being run in a valid module directory with a metadata.json
        PDK::CLI::Util.ensure_in_module!(
          message: '`pdk publish` can only be run from inside a valid module with a metadata.json.',
          log_level: :info
        )
        opts[:force] = true unless PDK::CLI::Util.interactive?
        opts[:'forge-token'] ||= PDK::Util::Env['PDK_FORGE_TOKEN']

        if opts[:'forge-token'].nil? || opts[:'forge-token'].empty?
          PDK.logger.error 'You must supply a Forge API token either via `--forge-token` option or PDK_FORGE_TOKEN environment variable.'
          exit 1
        end

        # pdk publish doesn't need any additional tasks. Since we still want to preserve functionality for
        # the deprecated `pdk release` command, we'll just set all the skip flags to true.
        opts[:'skip-validation'] = true
        opts[:'skip-changelog'] = true
        opts[:'skip-dependency'] = true
        opts[:'skip-documentation'] = true
        opts[:'skip-build'] = true

        Release.send_analytics('publish', opts)

        release = PDK::Module::Release.new(nil, opts)
        release.run
      end

      module Release # rubocop:disable Lint/ConstantDefinitionInBlock
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
      end
    end
  end
end
