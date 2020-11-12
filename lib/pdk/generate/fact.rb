require 'pdk'

module PDK
  module Generate
    class Fact < PuppetObject
      def friendly_name
        'Custom Fact'.freeze
      end

      def template_files
        files = {
          'fact_spec.erb' => File.join('spec', 'unit', 'facter', object_name) + '_spec.rb',
        }
        return files if spec_only?
        files.merge(
          'fact.erb' => File.join('lib', 'facter', object_name) + '.rb',
        )
      end

      def template_data
        { name: object_name }
      end
    end
  end
end
