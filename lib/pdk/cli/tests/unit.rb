require 'cri'
require 'pdk/cli/util/option_validator'
require 'pdk/report'

require 'pdk/tests/unit'

module PDK
  module CLI
    module Test
      class Unit
        include PDK::CLI::Util

        def self.command
          @unit ||= Cri::Command.define do
            name 'unit'
            usage _("unit [options]")
            summary _("Run unit tests.")

            flag nil, :list, _("list all available unit tests and their descriptions")

            option nil, :tests, _("a comma-separated list of tests to run"), argument: :required do |values|
              OptionValidator.list(values)
            end

            option nil, :runner_options, _("options to pass through to the actual test-runner"), argument: :required

            run do |opts, args, cmd|
              report = nil

              if opts[:list]
                puts _("List of all available unit tests: (TODO)")
              end

              if opts[:tests]
                tests = opts.fetch(:tests)
              end

              # Note: Reporting may be delegated to the validation tool itself.
              if opts[:'report-file']
                format = opts.fetch(:'report-format', PDK::Report.default_format)
                report = Report.new(opts.fetch(:'report-file'), format)
              end

              PDK::Test::Unit.invoke(tests, report)
            end
          end
        end
      end
    end
  end
end
