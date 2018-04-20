require 'pdk/cli/util/option_validator'
require 'pdk/report'

module PDK::CLI
  @test_unit_cmd = @test_cmd.define_command do
    name 'unit'
    usage _('unit [options]')
    summary _('Run unit tests.')

    PDK::CLI.puppet_version_options(self)
    flag nil, :list, _('List all available unit test files.')
    flag nil, :parallel, _('Run unit tests in parallel.'), hidden: true
    flag :v, :verbose, _('More verbose output. Displays examples in each unit test file.')

    option nil, :tests, _('Specify a comma-separated list of unit test files to run.'), argument: :required, default: '' do |values|
      PDK::CLI::Util::OptionValidator.comma_separated_list?(values)
    end

    # TODO
    # option nil, :runner_options, _("options to pass through to the actual test-runner"), argument: :required

    run do |opts, _args, _cmd|
      require 'pdk/tests/unit'

      if opts[:'puppet-version'] && opts[:'pe-version']
        raise PDK::CLI::ExitWithError, _('You can not specify both --puppet-version and --pe-version at the same time.')
      end

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
        report = PDK::Report.new
        report_formats = if opts[:format]
                           PDK::CLI::Util::OptionNormalizer.report_formats(opts[:format])
                         else
                           [{
                             method: PDK::Report.default_format,
                             target: PDK::Report.default_target,
                           }]
                         end

        exit_code = PDK::Test::Unit.invoke(report, opts)

        report_formats.each do |format|
          report.send(format[:method], format[:target])
        end

        exit exit_code
      end
    end
  end
end
