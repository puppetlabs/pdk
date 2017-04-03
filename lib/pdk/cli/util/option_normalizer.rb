module PDK
  module CLI
    module Util
      class OptionNormalizer
        # Parse one or more format:target pairs.
        # @return [Array<Report>] An array of one or more Reports.
        def self.report_formats(formats, options = {})
          reports = []
          formats.each do |f|
            if f.include?(':')
              format, target = f.split(':')
            else
              format, target = f, PDK::Report.default_target
            end

            reports << Report.new(target, format)
          end

          reports
        end
      end
    end
  end
end
