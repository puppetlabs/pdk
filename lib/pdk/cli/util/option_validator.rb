module PDK
  module CLI
    module Util
      class OptionValidator
        def self.is_comma_separated_list?(list, _options = {})
          (list =~ %r{^[\w\-]+(?:,[\w\-]+)+$}) ? true : false
        end

        def self.enum(val, valid_entries, _options = {})
          vals = val.is_a?(Array) ? val : [val]
          invalid_entries = vals.reject { |e| valid_entries.include?(e) }

          unless invalid_entries.empty?
            raise _('Error: the following values are invalid: %{invalid_entries}') % { invalid_entries: invalid_entries }
          end

          val
        end

        # Validate the module name against the regular expression in the
        # documentation: https://docs.puppet.com/puppet/4.10/modules_fundamentals.html#allowed-module-names
        def self.is_valid_module_name?(string)
          !(string =~ %r{\A[a-z][a-z0-9_]*\Z}).nil?
        end

        # Validate a Puppet namespace against the regular expression in the
        # documentation: https://docs.puppet.com/puppet/4.10/lang_reserved.html#classes-and-defined-resource-types
        def self.is_valid_namespace?(string)
          return false if (string || '').split('::').last == 'init'

          !(string =~ %r{\A([a-z][a-z0-9_]*)(::[a-z][a-z0-9_]*)*\Z}).nil?
        end

        singleton_class.send(:alias_method, :is_valid_class_name?, :is_valid_namespace?)
        singleton_class.send(:alias_method, :is_valid_defined_type_name?, :is_valid_namespace?)

        # Validate that a class/defined type parameter matches the regular
        # expression in the documentation: https://docs.puppet.com/puppet/4.10/lang_reserved.html#parameters
        # The parameter should also not be a reserved word or overload
        # a metaparameter.
        def self.is_valid_param_name?(string)
          reserved_words = %w[trusted facts server_facts title name].freeze
          metaparams = %w[alias audit before loglevel noop notify require schedule stage subscribe tag].freeze
          return false if reserved_words.include?(string) || metaparams.include?(string)

          !(string =~ %r{\A[a-z][a-zA-Z0-9_]*\Z}).nil?
        end

        # Naive validation of a data type declaration. Extracts all the bare
        # words and compares them against a list of known data types.
        #
        # @todo This prevents the use of dynamic data types like TypeReferences
        #   but that shouldn't be a problem for the current feature set. This
        #   should be replaced eventually by something better (or just call
        #   Puppet::Pops::Types::TypesParser)
        def self.is_valid_data_type?(string)
          valid_types = %w[
            String Integer Float Numeric Boolean Array Hash Regexp Undef
            Default Class Resource Scalar Collection Variant Data Pattern Enum
            Tuple Struct Optional Catalogentry Type Any Callable NotUndef
          ].freeze

          string.scan(%r{\b(([a-zA-Z0-9_]+)(,|\[|\]|\Z))}) do |result|
            type = result[1]

            return false unless string =~ %r{\A[A-Z]}

            unless valid_types.include?(type)
              PDK.logger.warn(_("Non-standard data type '%{type}', check the generated files for mistakes") % { type: type })
            end
          end

          true
        end
      end
    end
  end
end
