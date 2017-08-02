require 'pdk/cli/util/option_validator'
require 'pdk/report'

module PDK::CLI
  @test_unit_cmd = @test_cmd.define_command do
    name 'unit'
    usage _('unit [options]')
    summary _('Run unit tests.')

    flag nil, :list, _('list all available unit tests and their descriptions')
    flag nil, :parallel, _('run unit tests in parallel'), hidden: true

    option nil, :tests, _('a comma-separated list of tests to run'), argument: :required, default: '' do |values|
      PDK::CLI::Util::OptionValidator.comma_separated_list?(values)
    end

    # TODO
    # option nil, :runner_options, _("options to pass through to the actual test-runner"), argument: :required

    run do |opts, _args, _cmd|
      require 'pdk/tests/unit'

      PDK::CLI::Util.ensure_in_module!

      report = nil

      if opts[:list]
        examples = PDK::Test::Unit.list
        if examples.empty?
          puts _('No examples found.')
        else
          puts _('Examples:')
          examples.each do |example|
            puts _("%{id}\t%{description}" % { id: example[:id], description: example[:full_description] })
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
