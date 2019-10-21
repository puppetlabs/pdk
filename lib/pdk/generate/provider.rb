require 'pdk'

module PDK
  module Generate
    class Provider < PuppetObject
      OBJECT_TYPE = :provider

      # Prepares the data needed to render the new defined type template.
      #
      # @return [Hash{Symbol => Object}] a hash of information that will be
      # provided to the defined type and defined type spec templates during
      # rendering.
      def template_data
        data = {
          name: object_name,
          provider_class: Provider.class_name_from_object_name(object_name),
        }

        data
      end

      def raise_precondition_error(error)
        raise PDK::CLI::ExitWithError, _('%{error}: Creating a provider needs some local configuration in your module.' \
          ' Please follow the docs at https://puppet.com/docs/puppet/latest/create_types_and_providers_resource_api.html.') % { error: error }
      end

      def check_preconditions
        super
        # These preconditions can be removed once the pdk-templates are carrying the puppet-resource_api gem by default, and have switched
        # the default mock_with value.
        sync_path = PDK::Util.find_upwards('.sync.yml')
        if sync_path.nil?
          raise_precondition_error(_('.sync.yml not found'))
        end
        sync = YAML.load_file(sync_path)
        if !sync.is_a? Hash
          raise_precondition_error(_('.sync.yml contents is not a Hash'))
        elsif !sync.key? 'Gemfile'
          raise_precondition_error(_('Gemfile configuration not found'))
        elsif !sync['Gemfile'].key? 'optional'
          raise_precondition_error(_('Gemfile.optional configuration not found'))
        elsif !sync['Gemfile']['optional'].key? ':development'
          raise_precondition_error(_('Gemfile.optional.:development configuration not found'))
        elsif sync['Gemfile']['optional'][':development'].none? { |g| g['gem'] == 'puppet-resource_api' }
          raise_precondition_error(_('puppet-resource_api not found in the Gemfile config'))
        elsif !sync.key? 'spec/spec_helper.rb'
          raise_precondition_error(_('spec/spec_helper.rb configuration not found'))
        elsif !sync['spec/spec_helper.rb'].key? 'mock_with'
          raise_precondition_error(_('spec/spec_helper.rb.mock_with configuration not found'))
        elsif !sync['spec/spec_helper.rb']['mock_with'] == ':rspec'
          raise_precondition_error(_('spec/spec_helper.rb.mock_with not set to \':rspec\''))
        end
      end

      # @return [String] the path where the new provider will be written.
      def target_object_path
        @target_object_path ||= File.join(module_dir, 'lib', 'puppet', 'provider', object_name, object_name) + '.rb'
      end

      # @return [String] the path where the new type will be written.
      def target_type_path
        @target_type_path ||= File.join(module_dir, 'lib', 'puppet', 'type', object_name) + '.rb'
      end

      # @return [String] the path where the tests for the new provider
      # will be written.
      def target_spec_path
        @target_spec_path ||= File.join(module_dir, 'spec', 'unit', 'puppet', 'provider', object_name, object_name) + '_spec.rb'
      end

      # @return [String] the path where the tests for the new type will be written.
      def target_type_spec_path
        @target_type_spec_path ||= File.join(module_dir, 'spec', 'unit', 'puppet', 'type', object_name) + '_spec.rb'
      end
    end
  end
end
