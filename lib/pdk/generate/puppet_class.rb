require 'pdk/generate/puppet_object'

module PDK
  module Generate
    class PuppetClass < PuppetObject
      OBJECT_TYPE = :class
      PUPPET_STRINGS_TYPE = 'puppet_classes'.freeze

      # Prepares the data needed to render the new Puppet class template.
      #
      # @return [Hash{Symbol => Object}] a hash of information that will be
      # provided to the class and class spec templates during rendering.
      def template_data
        data = { name: object_name }

        data
      end

      # Calculates the path to the .pp file that the new class will be written
      # to.
      #
      # @return [String] the path where the new class will be written.
      def target_object_path
        @target_pp_path ||= begin
          class_name_parts = object_name.split('::')[1..-1]
          class_name_parts << 'init' if class_name_parts.empty?

          "#{File.join(module_dir, 'manifests', *class_name_parts)}.pp"
        end
      end

      # Calculates the path to the file where the tests for the new class will
      # be written.
      #
      # @return [String] the path where the tests for the new class will be
      # written.
      def target_spec_path
        @target_spec_path ||= begin
          class_name_parts = object_name.split('::')

          # drop the module name if the object name contains multiple parts
          class_name_parts.delete_at(0) if class_name_parts.length > 1

          "#{File.join(module_dir, 'spec', 'classes', *class_name_parts)}_spec.rb"
        end
      end
    end
  end
end
