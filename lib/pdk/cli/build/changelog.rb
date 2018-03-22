module PDK::CLI
  @build_changelog_cmd = @build_cmd.define_command do
    name 'changelog'
    # XXX need to make other options pass through ?
    usage _('changelog -- [github_changelog_generator options]')
    summary _('(Experimental) Generate changelogs using the github_changelog_generator gem')
    # XXX Do description better
    description _(<<-EOF
[experimental] For advanced users, XXX
EOF
                 )
    # Ensure that the bundle is installed and tools are available before running any validations.
    PDK::Util::Bundler.ensure_bundle!
    begin
      # XXX Is it terrible to do this here?
      require 'github_changelog_generator'
      gcg_options = GitHubChangelogGenerator::Parser.default_options
      GitHubChangelogGenerator::ParserFile.new(gcg_options).parse!
      yaml = YAML.load_file('metadata.json')
      if yaml['source']
        m = yaml['source'].match(%r{([^/]+)/([^/]+?)(\.git)?$})
        project = m[2]
        user = m[1]
      end

    rescue LoadError
      raise 'Install github_changelog_generator to get access to automatic changelog generation'
    end

    option nil, :user, _('GitHub username'), argument: :required, default: gcg_options[:user] || user
    option nil, :project, _('GitHub repo name for this module'), argument: :required, default: gcg_options[:project] || project
    option nil, :'since-tag', _('GitHub tag to start generation from'), argument: :required, default: gcg_options[:since_tag]

    run do |opts, args, _cmd|
      PDK::Util::Bundler.ensure_bundle!
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
