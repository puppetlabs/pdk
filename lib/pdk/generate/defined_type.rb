require 'pdk/generate/puppet_object'

module PDK
  module Generate
    class DefinedType < PuppetObject
      OBJECT_TYPE = :defined_type
      PUPPET_STRINGS_TYPE = 'defined_types'.freeze

      # Prepares the data needed to render the new defined type template.
      #
      # @return [Hash{Symbol => Object}] a hash of information that will be
      # provided to the defined type and defined type spec templates during
      # rendering.
      def template_data
        data = { name: object_name }

        data
      end

      # Calculates the path to the .pp file that the new defined type will be
      # written to.
      #
      # @return [String] the path where the new defined type will be written.
      def target_object_path
        @target_pp_path ||= begin
          define_name_parts = object_name.split('::')[1..-1]
          define_name_parts << 'init' if define_name_parts.empty?

          "#{File.join(module_dir, 'manifests', *define_name_parts)}.pp"
        end
      end

      # Calculates the path to the file where the tests for the new defined
      # type will be written.
      #
      # @return [String] the path where the tests for the new defined type
      # will be written.
      def target_spec_path
        @target_spec_path ||= begin
          define_name_parts = object_name.split('::')

          # drop the module name if the object name contains multiple parts
          define_name_parts.delete_at(0) if define_name_parts.length > 1

          "#{File.join(module_dir, 'spec', 'defines', *define_name_parts)}_spec.rb"
        end
      end
    end
  end
end
