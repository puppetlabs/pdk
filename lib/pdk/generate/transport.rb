require 'pdk'

module PDK
  module Generate
    class Transport < PuppetObject
      def friendly_name
        'Resource API Transport'.freeze
      end

      def template_files
        # Note : Due to how the V1 templates work, the names of the source template files may be mismatched to
        # their destination, e.g. transport_type.erb is really a transport schema
        files = {
          'transport_spec.erb'      => File.join('spec', 'unit', 'puppet', 'transport', object_name) + '_spec.rb',
          'transport_type_spec.erb' => File.join('spec', 'unit', 'puppet', 'transport', 'schema', object_name) + '_spec.rb',
        }
        return files if spec_only?
        files.merge(
          'transport.erb' => File.join('lib', 'puppet', 'transport', object_name) + '.rb',
          'transport_device.erb'    => File.join('lib', 'puppet', 'util', 'network_device', object_name, 'device.rb'),
          'transport_type.erb'      => File.join('lib', 'puppet', 'transport', 'schema', object_name) + '.rb',
        )
      end

      def template_data
        {
          name: object_name,
          transport_class: class_name_from_object_name(object_name),
        }
      end
    end
  end
end
