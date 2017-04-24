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
            raise _("Error: the following values are invalid: %{invalid_entries}") % {invalid_entries: invalid_entries}
          end

          val
        end

        # Validate the module name against the regular expression in the
        # documentation: https://docs.puppet.com/puppet/4.10/modules_fundamentals.html#allowed-module-names
        def self.is_valid_module_name?(string)
          !(string =~ /\A[a-z][a-z0-9_]*\Z/).nil?
        end
      end
    end
  end
end
