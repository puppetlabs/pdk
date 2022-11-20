require 'pdk'

module PDK
  class Config
    class IniFileSetting < PDK::Config::Setting
      # Initialises the PDK::Config::JSONSchemaSetting object.
      #
      # @see PDK::Config::Setting.initialize
      def initialize(_name, namespace, initial_value = nil)
        raise 'The IniFileSetting object can only be created within the IniFile Namespace' unless namespace.is_a?(PDK::Config::IniFile)
        super
        validate!(initial_value) unless initial_value.nil?
      end

      # Verifies that the new setting value is valid in an Ini File
      #
      # @see PDK::Config::Setting.validate!
      def validate!(value)
        # We're very restrictive here. Realistically Ini files only have string types
        return if value.nil? || value.is_a?(String) || value.is_a?(Integer)
        # The only other valid-ish type is a Hash
        unless value.is_a?(Hash)
          raise ArgumentError, 'The setting %{key} may only be a String or Integer, not %{class}' % {
            key:  qualified_name,
            class: value.class,
          }
        end
        # Any hashes can only have a single String/Integer value
        value.each do |child_name, child_value|
          next if child_value.nil? || child_value.is_a?(String) || child_value.is_a?(Integer)
          raise ArgumentError, 'The setting %{key} may only be a String or Integer, not %{class}' % {
            key:   qualified_name + '.' + child_name,
            class: child_value.class,
          }
        end
      end
    end
  end
end
