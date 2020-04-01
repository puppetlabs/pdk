require 'pdk'

module PDK
  module Generate
    class PuppetClass < PuppetObject
      PUPPET_STRINGS_TYPE = 'puppet_classes'.freeze

      def initialize(*_args)
        super
        object_name_parts = @object_name.split('::')

        @object_name = if object_name_parts.first == module_name
                         object_name
                       else
                         [module_name, object_name].join('::')
                       end
      end

      def friendly_name
        'Puppet Class'.freeze
      end

      def template_files
        # Calculate the class tests name
        class_name_parts = object_name.split('::')
        # Drop the module name if the object name contains multiple parts
        class_name_parts.delete_at(0) if class_name_parts.length > 1
        files = { 'class_spec.erb' => File.join('spec', 'classes', *class_name_parts) + '_spec.rb' }
        return files if spec_only?

        class_name_parts = object_name.split('::')[1..-1]
        class_name_parts << 'init' if class_name_parts.empty?
        files['class.erb'] = File.join('manifests', *class_name_parts) + '.pp'

        files
      end

      def template_data
        { name: object_name }
      end
    end
  end
end
