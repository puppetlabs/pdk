require 'spec_helper_acceptance'

describe 'pdk new provider', module_command: true do
  def update_module!
    command('pdk update --force').exit_status
  end

  context 'when run inside of a module' do
    include_context 'in a new module', 'new_provider'

    describe command('pdk new provider test_provider') do
      its(:stdout) { is_expected.to match(%r{#{File.join('lib', 'puppet', 'type', 'test_provider.rb')}}) }
      its(:stdout) { is_expected.to match(%r{#{File.join('lib', 'puppet', 'provider', 'test_provider', 'test_provider.rb')}}) }
      its(:stdout) { is_expected.to match(%r{#{File.join('spec', 'unit', 'puppet', 'provider', 'test_provider', 'test_provider_spec.rb')}}) }
      its(:stdout) { is_expected.to match(%r{#{File.join('spec', 'unit', 'puppet', 'type', 'test_provider_spec.rb')}}) }
      its(:stderr) { is_expected.to have_no_output }
      its(:exit_status) { is_expected.to eq(0) }

      describe file(File.join('lib', 'puppet', 'type')) do
        it { is_expected.to be_directory }
      end

      describe file(File.join('lib', 'puppet', 'type', 'test_provider.rb')) do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{Puppet::ResourceApi.register_type}) }
        its(:content) { is_expected.to match(%r{name: 'test_provider'}) }
      end

      describe file(File.join('lib', 'puppet', 'provider', 'test_provider')) do
        it { is_expected.to be_directory }
      end

      describe file(File.join('lib', 'puppet', 'provider', 'test_provider', 'test_provider.rb')) do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{class Puppet::Provider::TestProvider::TestProvider}) }
      end

      describe file(File.join('spec', 'unit', 'puppet', 'provider', 'test_provider')) do
        it { is_expected.to be_directory }
      end

      describe file(File.join('spec', 'unit', 'puppet', 'provider', 'test_provider', 'test_provider_spec.rb')) do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{RSpec.describe Puppet::Provider::TestProvider::TestProvider do}) }
      end

      describe file(File.join('spec', 'unit', 'puppet', 'type')) do
        it { is_expected.to be_directory }
      end

      describe file(File.join('spec', 'unit', 'puppet', 'type', 'test_provider_spec.rb')) do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{RSpec.describe 'the test_provider type' do}) }
      end

      describe command('pdk validate ruby') do
        its(:stdout) { is_expected.to have_no_output }
        its(:stderr) { is_expected.to match(%r{using ruby \d+\.\d+\.\d+}i) }
        its(:stderr) { is_expected.to match(%r{using puppet \d+\.\d+\.\d+}i) }
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk test unit') do
        its(:stdout) { is_expected.to match(%r{0 failures}) }
        its(:stdout) { is_expected.not_to match(%r{no examples found}i) }
        its(:exit_status) { is_expected.to eq(0) }
      end
    end
  end
end
