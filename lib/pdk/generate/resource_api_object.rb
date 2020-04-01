require 'pdk'

module PDK
  module Generate
    # An abstract class for generated objects that require the Puppet Resource API Gem
    #
    # @abstract
    class ResourceAPIObject < PuppetObject
      #:nocov: This is tested in spec/acceptance/new_transport_spec.rb
      # @see PDK::Generate::PuppetObject.check_preconditions
      def check_preconditions
        super
        # Note that these preconditions are only applicable to the current (V1) template rendering layout and will need to be changed
        # when additional template renderers are introduced.
        #
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

      # Helper method to raise an error if the Resource API is not available
      #
      # @api private
      def raise_precondition_error(error)
        raise PDK::CLI::ExitWithError, _('%{error}: Creating a %{thing_name} needs some local configuration in your module.' \
          ' Please follow the docs at https://puppet.com/docs/puppet/latest/create_types_and_providers_resource_api.html') % {
            thing_name: friendly_name,
            error: error,
          }
      end
      #:nocov:
    end
  end
end
