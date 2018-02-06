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

      # TODO: Ensure forge metadata has been set, or call out to interview
      #       to set it.
      #
      # module_metadata.interview_for_forge! unless module_metadata.forge_ready?

      PDK::Module::Build.invoke(opts)
    end
  end
end
