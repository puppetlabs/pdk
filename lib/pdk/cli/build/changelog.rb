
module PDK::CLI
  @build_changelog_cmd = @build_cmd.define_command do
    name 'changelog'
    usage _('changelog -- [github_changelog_generator_options]')
    summary _('(Experimental) Generate changelogs using the github_changelog_generator gem')
    description _(<<-EOF
[experimental] For advanced users, XXX
EOF
                 )
    option nil, :user, _('GitHub username'), argument: :required
    option nil, :project, _('GitHub repo name for this module'), argument: :required
    option nil, :since_tag, _('GitHub repo name for this module'), argument: :required

    run do |_opts, args, _cmd|
      require 'pdk/build/changelog'

      PDK::CLI::Util.ensure_in_module!(
        message: _('`pdk build changelog` can only be run from inside a valid module directory.'),
        log_level: :info,
      )

      module_dir = Dir.pwd
      PDK::Build::Changelog.build(module_dir, opts)
    end
  end
end
