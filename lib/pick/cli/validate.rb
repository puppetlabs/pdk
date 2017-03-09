require 'cri'
require 'pick/cli/util/option_validator'

include Pick::CLI::Util

module Pick
  module CLI
    class Validate
      def self.command
        @validate ||= Cri::Command.define do
          name 'validate'
          usage 'validate [options]'
          summary 'Run static analysis tests.'
          description 'Run metadata-json-lint, puppet parser validate, puppet-lint, or rubocop.'

          flag :h, :help, 'validate help' do |value, cmd|
            puts cmd.help
            exit 0
          end

          flag nil, :list, 'list all available validators'
          option nil, :validators, "Available validators: #{Pick::Validate.validators.map(&:cmd).join(', ')}", argument: :required do |values|
            # Ensure the argument is a comma separated list and that each validator exists
            OptionValidator.enum(OptionValidator.list(values), Pick::Validate.validators.map(&:cmd))
          end

          run do |opts, args, cmd|
            validators = Pick::Validate.validators
            report = nil

            if opts[:list]
              Pick::Validate.validators.each { |v| puts v.cmd }
              exit 0
            end

            if opts[:validators]
              vals = OptionValidator.list(opts.fetch(:validators))
              validators = Pick::Validate.validators.find_all { |v| vals.include?(v.cmd) }
            end

            # Note: Reporting may be delegated to the validation tool itself.
            if opts[:'report-file']
              format = opts.fetch(:'report-format', Pick::Report.default_format)
              report = Report.new(opts.fetch(:'report-file'), format)
            end

            validators.each do |validator|
              validator.invoke(report)
            end
          end
        end
      end
    end
  end
end
