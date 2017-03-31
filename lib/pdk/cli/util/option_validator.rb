module PDK
  module CLI
    module Util
      class OptionValidator
        def self.is_comma_separated_list?(list, options = {})
          list =~ /^[\w\-]+(?:,[\w\-]+)+$/ ? true : false
        end

        def self.enum(val, valid_entries, options = {})
          vals = val.is_a?(Array) ? val : [val]
          invalid_entries = vals.find_all { |e| !valid_entries.include?(e) }

          unless invalid_entries.empty?
            raise "Error: the following values are invalid: #{invalid_entries}"
          end

          val
        end
      end
    end
  end
end
