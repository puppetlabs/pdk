module PDK
  module CLI
    module Util
      class OptionValidator
        def self.comma_separated_list?(list, _options = {})
          (list =~ %r{^[\w\-]+(?:,[\w\-]+)+$}) ? true : false
        end

        def self.enum(val, valid_entries, _options = {})
          vals = val.is_a?(Array) ? val : [val]
          invalid_entries = vals.reject { |e| valid_entries.include?(e) }

          unless invalid_entries.empty?
            raise ArgumentError, _('Error: the following values are invalid: %{invalid_entries}') % { invalid_entries: invalid_entries }
          end

          val
        end

        # Validate the module name against the regular expression in the
        # documentation: https://docs.puppet.com/puppet/4.10/modules_fundamentals.html#allowed-module-names
        def self.valid_module_name?(string)
          !(string =~ %r{\A[a-z][a-z0-9_]*\Z}).nil?
        end
        singleton_class.send(:alias_method, :valid_task_name?, :valid_module_name?)

        # Validate a Puppet namespace against the regular expression in the
        # documentation: https://docs.puppet.com/puppet/4.10/lang_reserved.html#classes-and-defined-resource-types
        def self.valid_namespace?(string)
          return false if (string || '').split('::').last == 'init'

          !(string =~ %r{\A([a-z][a-z0-9_]*)(::[a-z][a-z0-9_]*)*\Z}).nil?
        end

        singleton_class.send(:alias_method, :valid_class_name?, :valid_namespace?)
        singleton_class.send(:alias_method, :valid_defined_type_name?, :valid_namespace?)

        # Validate that a class/defined type parameter matches the regular
        # expression in the documentation: https://docs.puppet.com/puppet/4.10/lang_reserved.html#parameters
        # The parameter should also not be a reserved word or overload
        # a metaparameter.
        def self.valid_param_name?(string)
          reserved_words = %w[trusted facts server_facts title name].freeze
          metaparams = %w[alias audit before loglevel noop notify require schedule stage subscribe tag].freeze
          return false if reserved_words.include?(string) || metaparams.include?(string)

          !(string =~ %r{\A[a-z][a-zA-Z0-9_]*\Z}).nil?
        end
      end
    end
  end
end
