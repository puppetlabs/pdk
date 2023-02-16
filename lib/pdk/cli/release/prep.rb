require 'pdk/cli/release'

module PDK::CLI
  @release_prep_cmd = @release_cmd.define_command do
    name 'prep'
    usage 'prep [options]'
    summary '(Experimental) Performs all the pre-release checks to ensure module is ready to be released'

    flag nil, :force,                'Prepare the module automatically, with no prompts.'
    flag nil, :'skip-validation',    'Skips the module validation check.'
    flag nil, :'skip-changelog',     'Skips the automatic changelog generation.'
    flag nil, :'skip-dependency',    'Skips the module dependency check.'
    flag nil, :'skip-documentation', 'Skips the documentation update.'

    option nil, :version, 'Update the module to the specified version prior to release. When not specified, the new version will be computed from the Changelog where possible.',
           argument: :required

    run do |opts, _args, cmd|
      # Make sure build is being run in a valid module directory with a metadata.json
      PDK::CLI::Util.ensure_in_module!(
        message:   "`pdk release #{cmd.name}` can only be run from inside a valid module with a metadata.json.",
        log_level: :info,
      )

      opts[:'skip-build'] = true
      opts[:'skip-publish'] = true

      Release.prepare_interview(opts) unless opts[:force]

      Release.send_analytics("release #{cmd.name}", opts)

      release = PDK::Module::Release.new(nil, opts)

      Release.module_compatibility_checks!(release, opts)

      release.run
    end
  end
end
