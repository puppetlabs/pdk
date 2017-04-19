require 'spec_helper'

describe PDK::Module::Metadata do
  context 'when processing and validating metadata' do
    let (:metadata) { PDK::Module::Metadata.new.update(
                        'name' => 'foo-bar',
                        'version' => '0.1.0',
                        'dependencies' => [
                          { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' }
                        ]
                      )
                    }

    it 'should error when the provided name is not namespaced' do
      expect { metadata.update({'name' => 'foo'}) }.to raise_error(ArgumentError, "Invalid 'name' field in metadata.json: the field must be a dash-separated username and module name")
    end

    it 'should error when the provided name contains non-alphanumeric characters' do
      expect { metadata.update({'name' => 'foo-@bar'}) }.to raise_error(ArgumentError, "Invalid 'name' field in metadata.json: the module name contains non-alphanumeric (or underscore) characters")
    end

    it 'should error when the provided name starts with a non-letter character' do
      expect { metadata.update({'name' => 'foo-1bar'}) }.to raise_error(ArgumentError, "Invalid 'name' field in metadata.json: the module name must begin with a letter")
    end
  end
end
