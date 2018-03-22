# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'pdk new provider foo', module_command: true do
  context 'in a new module' do
    include_context 'in a new module', 'new_provider'

    context 'when creating a provider' do
      before(:all) do
        File.open('.sync.yml', 'w') do |f|
          f.write(<<~SYNC)
            ---
            Gemfile:
              optional:
                ':development':
                  - gem: 'puppet-resource_api'
            spec/spec_helper.rb:
              mock_with: ':rspec'
SYNC
        end
        system('pdk convert --force')
      end

      describe command('pdk new provider test_provider') do
        its(:stderr) { is_expected.to match(%r{creating .* from template}i) }
        its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
        its(:stdout) { is_expected.to match(%r{\A\Z}) }
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe file('lib/puppet/type') do
        it { is_expected.to be_directory }
      end

      describe file('lib/puppet/type/test_provider.rb') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{Puppet::ResourceApi.register_type}) }
        its(:content) { is_expected.to match(%r{name: 'test_provider'}) }
      end

      describe file('lib/puppet/provider/test_provider') do
        it { is_expected.to be_directory }
      end

      describe file('lib/puppet/provider/test_provider/test_provider.rb') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{class Puppet::Provider::TestProvider::TestProvider}) }
      end

      describe file('spec/unit/puppet/provider/test_provider') do
        it { is_expected.to be_directory }
      end

      describe file('spec/unit/puppet/provider/test_provider/test_provider_spec.rb') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{RSpec.describe Puppet::Provider::TestProvider::TestProvider do}) }
      end

      describe file('spec/unit/puppet/type') do
        it { is_expected.to be_directory }
      end

      describe file('spec/unit/puppet/type/test_provider_spec.rb') do
        it { is_expected.to be_file }
        its(:content) { is_expected.to match(%r{RSpec.describe 'the test_provider type' do}) }
      end

      context 'when validating the generated code' do
        describe command('pdk validate ruby') do
          its(:stdout) { is_expected.to be_empty }
          its(:stderr) { is_expected.to be_empty }
          its(:exit_status) { is_expected.to eq(0) }
        end
      end

      context 'when running the generated spec tests' do
        describe command('pdk test unit') do
          its(:stderr) { is_expected.to match(%r{0 failures}) }
          its(:stderr) { is_expected.not_to match(%r{no examples found}i) }
          its(:exit_status) { is_expected.to eq(0) }
        end
      end

      context 'without a .sync.yml' do
        before(:all) do
          FileUtils.mv('.sync.yml', 'sync.yml.orig')
        end

        describe command('pdk new provider test_provider2') do
          its(:stderr) { is_expected.to match(%r{pdk \(ERROR\): .sync.yml not found}i) }
          its(:stdout) { is_expected.to match(%r{\A\Z}) }
          its(:exit_status) { is_expected.not_to eq(0) }
        end
      end

      context 'with invalid .sync.yml' do
        before(:all) do
          File.open('.sync.yml', 'w') do |f|
            f.write(<<~SYNC)
              ---
              Gemfile:
                optional:
                  ':wrong_group':
                    - gem: 'puppet-resource_api'
              spec/spec_helper.rb:
                mock_with: ':rspec'
SYNC
          end
          system('pdk convert --force')
        end

        describe command('pdk new provider test_provider2') do
          its(:stderr) { is_expected.to match(%r{pdk \(ERROR\): Gemfile.optional.:development configuration not found}i) }
          its(:stdout) { is_expected.to match(%r{\A\Z}) }
          its(:exit_status) { is_expected.not_to eq(0) }
        end
      end
    end
  end
end
