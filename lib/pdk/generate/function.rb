require 'pdk'

module PDK
  module Generate
    class Function < PuppetObject
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
        'Function'.freeze
      end

      def template_files
        # Calculate the function tests name
        func_name_parts = object_name.split('::')
        # Drop the module name if the object name contains multiple parts
        func_name_parts.delete_at(0) if func_name_parts.length > 1
        files = {
          File.join('functions', 'function_spec.erb') => File.join('spec', 'functions', *func_name_parts) + '_spec.rb',
        }
        return files if spec_only?
        func_name_parts = object_name.split('::')[1..-1]
        template_file = File.join('functions', "#{options[:type]}_function.erb")

        files[template_file] = if options[:type].eql?('v4')
                                 File.join('lib', 'puppet', 'functions', module_name, *func_name_parts) + '.rb'
                               else
                                 File.join('functions', *func_name_parts) + '.pp'
                               end
        files
      end

      def template_data
        func_name = object_name.split('::').last
        namespace = object_name.split('::')[0...-1].join('::')
        { name: object_name, func_name: func_name, namespace: namespace }
      end
    end
  end
end
