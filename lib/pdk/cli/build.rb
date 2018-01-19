require 'pdk/cli/util'

module PDK::CLI
  @build_cmd = @base_cmd.define_command do
    name 'build'
    usage _('build [options]')
    summary _('Builds a package from the module that can be published to the Puppet Forge.')

    option nil, 'target-dir',
           _('The target directory where you want PDK to write the package.'),
           argument: :required, default: File.join(Dir.pwd, 'pkg')

    be_hidden

    run do |opts, _args, _cmd|
      require 'pdk/module/build'

      PDK::CLI::Util.ensure_in_module!(
        message:   _('`pdk build` can only be run from inside a valid module directory.'),
        log_level: :info,
      )

      module_metadata = PDK::Module::Metadata.from_file('metadata.json')

      # TODO: Ensure forge metadata has been set, or call out to interview
      #       to set it.
      #
      # module_metadata.interview_for_forge! unless module_metadata.forge_ready?

      PDK.logger.info _('Building %{module_name} version %{module_version}') % {
        module_name:    module_metadata.data['name'],
        module_version: module_metadata.data['version'],
      }

      package_path = PDK::Module::Build.invoke(opts)

      PDK.logger.info _('Build of %{package_name} has completed successfully. Built package can be found here: %{package_path}') % {
        package_name: 'something',
        package_path: package_path,
      }
    end
  end
end
