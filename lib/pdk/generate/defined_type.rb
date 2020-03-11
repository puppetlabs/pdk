require 'pdk'

module PDK
  module Generate
    class DefinedType < PuppetObject
      PUPPET_STRINGS_TYPE = 'defined_types'.freeze

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
        'Defined Type'.freeze
      end

      def template_files
        # Calculate the defined type tests name
        define_name_parts = object_name.split('::')
        # drop the module name if the object name contains multiple parts
        define_name_parts.delete_at(0) if define_name_parts.length > 1
        files = { 'defined_type_spec.erb' => File.join('spec', 'defines', *define_name_parts) + '_spec.rb' }
        return files if spec_only?

        define_name_parts = object_name.split('::')[1..-1]
        define_name_parts << 'init' if define_name_parts.empty?
        files['defined_type.erb'] = File.join('manifests', *define_name_parts) + '.pp'

        files
      end

      def template_data
        { name: object_name }
      end
    end
  end
end
