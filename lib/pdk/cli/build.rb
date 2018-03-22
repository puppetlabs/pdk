require 'pdk/cli/util'

module PDK::CLI
  @build_cmd = @base_cmd.define_command do
    name 'build'
    usage _('build [options]')
    summary _('Builds a package from the module that can be published to the Puppet Forge.')

    option nil, 'target-dir',
           _('The target directory where you want PDK to write the package.'),
           argument: :required, default: File.join(Dir.pwd, 'pkg')

    option nil, 'force', _('Skips the prompts and builds the module package.')

    run do |opts, _args, _cmd|
      require 'pdk/module/build'

      # Make sure build is being run in a valid module directory with a metadata.json
      PDK::CLI::Util.ensure_in_module!(
        message:   _('`pdk build` can only be run from inside a valid module with a metadata.json.'),
        log_level: :info,
      )

      module_metadata = PDK::Module::Metadata.from_file('metadata.json')

      # TODO: Ensure forge metadata has been set, or call out to interview
      #       to set it.
      #
      unless module_metadata.forge_ready?
        if opts[:force]
          PDK.logger.error _('This module is missing required fields in the metadata.json. Re-run the build command without --force to add this information.')
          exit 1
        else
          module_metadata.interview_for_forge!
          module_metadata.write!('metadata.json')
        end
      end

      builder = PDK::Module::Build.new(opts)

      unless opts[:force]
        if builder.package_already_exists?
          PDK.logger.info _("The file '%{package}' already exists.") % { package: builder.package_file }

          unless PDK::CLI::Util.prompt_for_yes(_('Overwrite?'), default: false)
            PDK.logger.info _('Build cancelled; exiting.')
            exit 0
          end
        end

        unless builder.module_pdk_compatible?
          PDK.logger.info _('This module is not compatible with PDK, so PDK can not validate or test this build. ' \
                            'Unvalidated modules may have errors when uploading to the Forge. ' \
                            'To make this module PDK compatible and use validate features, cancel the build and run `pdk convert`.')

          unless PDK::CLI::Util.prompt_for_yes(_('Continue build without converting?'))
            PDK.logger.info _('Build cancelled; exiting.')
            exit 0
          end
        end
      end

      PDK.logger.info _('Building %{module_name} version %{module_version}') % {
        module_name:    module_metadata.data['name'],
        module_version: module_metadata.data['version'],
      }

      builder.build

      PDK.logger.info _('Build of %{package_name} has completed successfully. Built package can be found here: %{package_path}') % {
        package_name: module_metadata.data['name'],
        package_path: builder.package_file,
      }
    end
  end
end

require 'pdk/cli/build/changelog'
