module PDK
  module CLI
    module Util
      class OptionNormalizer
        def self.comma_separated_list_to_array(list, _options = {})
          raise _('Error: expected comma separated list') unless OptionValidator.comma_separated_list?(list)
          list.split(',').compact
        end

        # Parse one or more format:target pairs into report format
        # specifications.
        #
        # Each specification is a Hash with two values:
        #   :method => The name of the method to call on the PDK::Report object
        #              to render the report.
        #   :target => The target to write the report to. This can be either an
        #              IO object that implements #write, or a String filename
        #              that will be opened for writing.
        #
        # If the target given is "stdout" or "stderr", this will convert those
        # strings into the appropriate IO object.
        #
        # @return [Array<Hash{Symbol=>Object}>] An array of one or more report
        #   format specifications
        def self.report_formats(formats)
          formats.map do |f|
            format, target = f.split(':', 2)

            begin
              OptionValidator.enum(format, PDK::Report.formats)
            rescue ArgumentError
              raise PDK::CLI::FatalError, _("'%{name}' is not a valid report format (%{valid})") % {
                name:  format,
                valid: PDK::Report.formats.join(', '),
              }
            end

            case target
            when 'stdout'
              target = $stdout
            when 'stderr'
              target = $stderr
            when nil
              target = PDK::Report.default_target
            end

            { method: "write_#{format}".to_sym, target: target }
          end
        end

        def self.parameter_specification(value)
          param_name, param_type = value.split(':', 2)
          param_type = 'String' if param_type.nil?

          unless PDK::CLI::Util::OptionValidator.valid_param_name?(param_name)
            raise PDK::CLI::FatalError, _("'%{name}' is not a valid parameter name") % {
              name: param_name,
            }
          end

          unless PDK::CLI::Util::OptionValidator.valid_data_type?(param_type)
            raise PDK::CLI::FatalError, _("'%{type}' is not a valid data type") % {
              type: param_type,
            }
          end

          { name: param_name, type: param_type }
        end
      end
    end
  end
end
