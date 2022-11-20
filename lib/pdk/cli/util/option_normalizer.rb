require 'pdk'

module PDK
  module CLI
    module Util
      class OptionNormalizer
        def self.comma_separated_list_to_array(list, _options = {})
          raise 'Error: expected comma separated list' unless OptionValidator.comma_separated_list?(list)
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
              raise PDK::CLI::ExitWithError, "'%{name}' is not a valid report format (%{valid})" % {
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
      end
    end
  end
end
