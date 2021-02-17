require 'pdk'

module PDK
  module Generate
    class Provider < PuppetObject
      def friendly_name
        'Resource API Provider'.freeze
      end

      def template_files
        files = {
          'provider_spec.erb'      => File.join('spec', 'unit', 'puppet', 'provider', object_name, object_name) + '_spec.rb',
          'provider_type_spec.erb' => File.join('spec', 'unit', 'puppet', 'type', object_name) + '_spec.rb',
        }
        return files if spec_only?
        files.merge(
          'provider.erb' => File.join('lib', 'puppet', 'provider', object_name, object_name) + '.rb',
          'provider_type.erb' => File.join('lib', 'puppet', 'type', object_name) + '.rb',
        )
      end

      def template_data
        { name: object_name,
          provider_class: class_name_from_object_name(object_name) }
      end
    end
  end
end
