module PDK::CLI
  @build_cmd = @base_cmd.define_command do
    name 'build'
    usage 'build [options]'
    summary 'Builds a package from the module that can be published to the Puppet Forge.'

    option nil, 'target-dir',
           'The target directory where you want PDK to write the package.',
           argument: :required, default: File.join(Dir.pwd, 'pkg')

    option nil, 'force', 'Skips the prompts and builds the module package.'

    run do |opts, _args, _cmd|
      require 'pdk/module/build'
      require 'pdk/module/metadata'
      require 'pdk/cli/util'

      # Make sure build is being run in a valid module directory with a metadata.json
      PDK::CLI::Util.ensure_in_module!(
        message:   '`pdk build` can only be run from inside a valid module with a metadata.json.',
        log_level: :info,
      )

      PDK::CLI::Util.analytics_screen_view('build', opts)

      module_metadata = PDK::Module::Metadata.from_file('metadata.json')

      # TODO: Ensure forge metadata has been set, or call out to interview
      #       to set it.
      #
      unless module_metadata.forge_ready?
        if opts[:force]
          PDK.logger.warn "This module is missing the following fields in the metadata.json: #{module_metadata.missing_fields.join(', ')}. " \
                          'These missing fields may affect the visibility of the module on the Forge.'
        else
          module_metadata.interview_for_forge!
          module_metadata.write!('metadata.json')
        end
      end

      builder = PDK::Module::Build.new(opts)

      unless opts[:force]
        if builder.package_already_exists?
          PDK.logger.info "The file '%{package}' already exists." % { package: builder.package_file }

          unless PDK::CLI::Util.prompt_for_yes('Overwrite?', default: false)
            PDK.logger.info 'Build cancelled; exiting.'
            exit 0
          end
        end

        unless builder.module_pdk_compatible?
          PDK.logger.info 'This module is not compatible with PDK, so PDK can not validate or test this build. ' \
                          'Unvalidated modules may have errors when uploading to the Forge. ' \
                          'To make this module PDK compatible and use validate features, cancel the build and run `pdk convert`.'

          unless PDK::CLI::Util.prompt_for_yes('Continue build without converting?')
            PDK.logger.info 'Build cancelled; exiting.'
            exit 0
          end
        end
      end

      PDK.logger.info 'Building %{module_name} version %{module_version}' % {
        module_name:    module_metadata.data['name'],
        module_version: module_metadata.data['version'],
      }

      builder.build

      PDK.logger.info 'Build of %{package_name} has completed successfully. Built package can be found here: %{package_path}' % {
        package_name: module_metadata.data['name'],
        package_path: builder.package_file,
      }
    end
  end
end
