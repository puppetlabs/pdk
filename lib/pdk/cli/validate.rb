require 'cri'
require 'pdk/cli/util/option_validator'
require 'pdk/report'

require 'pdk/validate'

module PDK
  module CLI
    class Validate
      include PDK::CLI::Util

      def self.command
        @validate ||= Cri::Command.define do
          name 'validate'
          usage _('validate [options]')
          summary _('Run static analysis tests.')
          description _('Run metadata-json-lint, puppet parser validate, puppet-lint, or rubocop.')

          flag nil, :list, _('list all available validators')

          run do |opts, args, _cmd|
            validator_names = PDK::Validate.validators.map { |v| v.name }
            validators = PDK::Validate.validators
            targets = []
            reports = nil

            if opts[:list]
              puts _('Available validators: %{validator_names}') % { validator_names: validator_names.join(', ') }
              exit 0
            end

            if args[0]
              # This may be a single validator, a list of validators, or a target.
              if OptionValidator.is_comma_separated_list?(args[0])
                # This is a comma separated list. Treat each item as a validator.

                vals = OptionNormalizer.comma_separated_list_to_array(args[0])
                validators = PDK::Validate.validators.find_all { |v| vals.include?(v.name) }

                invalid = vals.find_all { |v| !validator_names.include?(v) }
                invalid.each do |v|
                  PDK.logger.warn(_("Unknown validator '%{v}'. Available validators: %{validators}") % { v: v, validators: validator_names.join(', ') })
                end
              else
                # This is a single item. Check if it's a known validator, or otherwise treat it as a target.
                val = PDK::Validate.validators.find { |v| args[0] == v.name }
                if val
                  validators = [val]
                else
                  targets = [args[0]]
                  # We now know that no validators were passed, so let the user know we're using all of them by default.
                  PDK.logger.info(_('Running all available validators...'))
                end
              end
            else
              PDK.logger.info(_('Running all available validators...'))
            end

            # Subsequent arguments are targets.
            targets.concat(args[1..-1]) if args.length > 1

            # Note: Reporting may be delegated to the validation tool itself.
            if opts[:format]
              reports = OptionNormalizer.report_formats(opts.fetch(:format))
            end

            options = targets.empty? ? {} : { targets: targets }
            validators.each do |validator|
              result = validator.invoke(options)
              if reports
                reports.each do |r|
                  r.write(result)
                end
              end
            end
          end
        end
      end
    end
  end
end
