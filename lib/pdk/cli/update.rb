module PDK::CLI
  @update_cmd = @base_cmd.define_command do
    name 'update'
    usage 'update [options]'
    summary 'Update a module that has been created by or converted for use by PDK.'

    flag nil, :noop, 'Do not update the module, just output what would be done.'
    flag nil, :force, 'Update the module automatically, with no prompts.'

    PDK::CLI.template_ref_option(self)

    run do |opts, _args, _cmd|
      # Write the context information to the debug log
      PDK.context.to_debug_log

      unless PDK.context.is_a?(PDK::Context::Module)
        raise PDK::CLI::ExitWithError, '`pdk update` can only be run from inside a valid module directory.'
      end

      raise PDK::CLI::ExitWithError, 'This module does not appear to be PDK compatible. To make the module compatible with PDK, run `pdk convert`.' unless PDK::Util.module_pdk_compatible?

      if opts[:noop] && opts[:force]
        raise PDK::CLI::ExitWithError, 'You can not specify --noop and --force when updating a module'
      end

      if Gem::Version.new(PDK::VERSION) < Gem::Version.new(PDK::Util.module_pdk_version)
        PDK.logger.warn "This module has been updated to PDK #{PDK::Util.module_pdk_version} which is newer than your PDK version (#{PDK::VERSION}), proceed with caution!"

        unless opts[:force]
          raise PDK::CLI::ExitWithError,
                'Please update your PDK installation and try again. ' \
                'You may also use the --force flag to override this and ' \
                'continue at your own risk.'
        end
      end

      PDK::CLI::Util.analytics_screen_view('update', opts)

      updater = PDK::Module::Update.new(PDK.context.root_path, opts)

      if updater.pinned_to_puppetlabs_template_tag?
        PDK.logger.info 'This module is currently pinned to version %{current_version} ' \
                        'of the default template. If you would like to update your ' \
                        'module to the latest version of the template, please run `pdk ' \
                        'update --template-ref %{new_version}`.' % {
                          current_version: updater.template_uri.uri_fragment,
                          new_version: PDK::TEMPLATE_REF,
                        }
      end

      updater.run
    end
  end
end
