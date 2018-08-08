require 'pdk/cli/util/option_validator'
require 'pdk/report'

module PDK::CLI
  @test_unit_cmd = @test_cmd.define_command do
    name 'unit'
    usage _('unit [options]')
    summary _('Run unit tests.')

    PDK::CLI.puppet_version_options(self)
    PDK::CLI.puppet_dev_option(self)
    flag nil, :list, _('List all available unit test files.')
    flag nil, :parallel, _('Run unit tests in parallel.')
    flag :v, :verbose, _('More verbose --list output. Displays a list of examples in each unit test file.')
    flag :c, 'clean-fixtures', _('Clean up downloaded fixtures after the test run.')

    option nil, :tests, _('Specify a comma-separated list of unit test files to run.'), argument: :required, default: '' do |values|
      PDK::CLI::Util::OptionValidator.comma_separated_list?(values)
    end

    # TODO
    # option nil, :runner_options, _("options to pass through to the actual test-runner"), argument: :required

    run do |opts, _args, _cmd|
      require 'pdk/tests/unit'

      PDK::CLI::Util.validate_puppet_version_opts(opts)

      PDK::CLI::Util.ensure_in_module!(
        message:   _('Unit tests can only be run from inside a valid module directory.'),
        log_level: :info,
      )

      PDK::CLI::Util.module_version_check

      report = nil

      if opts[:list]
        examples = PDK::Test::Unit.list
        if examples.empty?
          puts _('No unit test files with examples were found.')
        else
          puts _('Unit Test Files:')
          files = examples.map { |example| example[:file_path] }
          files.uniq.each do |file|
            puts _(file)

            next unless opts[:verbose]

            file_examples = examples.select { |example| example[:file_path] == file }
            file_examples.each do |file_example|
              puts _("\t%{id}\t%{description}" % { id: file_example[:id], description: file_example[:full_description] })
            end
          end
        end
      else
        PDK.logger.info _('--verbose has no effect when not used with --list') if opts[:verbose]

        report = PDK::Report.new
        report_formats = if opts[:format]
                           PDK::CLI::Util::OptionNormalizer.report_formats(opts[:format])
                         else
                           [{
                             method: PDK::Report.default_format,
                             target: PDK::Report.default_target,
                           }]
                         end

        # Ensure that the bundled gems are up to date and correct Ruby is activated before running tests.
        puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
        PDK::Util::PuppetVersion.fetch_puppet_dev if opts.key?(:'puppet-dev')
        PDK::Util::RubyVersion.use(puppet_env[:ruby_version])
        PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

        exit_code = PDK::Test::Unit.invoke(report, opts)

        report_formats.each do |format|
          report.send(format[:method], format[:target])
        end

        exit exit_code
      end
    end
  end
end
