module PDK
  module CLI
    module Util
      class OptionNormalizer
        def self.comma_separated_list_to_array(list, _options = {})
          raise _('Error: expected comma separated list') unless OptionValidator.is_comma_separated_list?(list)
          list.split(',').compact
        end

        # Parse one or more format:target pairs.
        # @return [Array<Report>] An array of one or more Reports.
        def self.report_formats(formats, _options = {})
          reports = []
          formats.each do |f|
            if f.include?(':')
              format, target = f.split(':')
            else
              format = f
              target = PDK::Report.default_target
            end

            reports << Report.new(target, format)
          end

          reports
        end

        def self.parameter_specification(value)
          param_name, param_type = value.split(':', 2)
          param_type = 'String' if param_type.nil?

          unless PDK::CLI::Util::OptionValidator.is_valid_param_name?(param_name)
            raise PDK::CLI::FatalError, _("'%{name}' is not a valid parameter name") % { name: param_name }
          end

          unless PDK::CLI::Util::OptionValidator.is_valid_data_type?(param_type)
            raise PDK::CLI::FatalError, _("'%{type}' is not a valid data type") % { type: param_type }
          end

          { name: param_name, type: param_type }
        end
      end
    end
  end
end
