require 'spec_helper_acceptance'

describe 'pdk new fact', module_command: true do
  shared_examples 'it creates a fact' do |options|
    describe file(options[:name]) do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{fact #{options[:name]} }) }
    end

    describe file(options[:spec]) do
      it { is_expected.to be_file }
      its(:content) { is_expected.to match(%r{describe '#{options[:name]}' do}) }
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{0 failures}) }
      its(:stdout) { is_expected.not_to match(%r{no examples found}i) }
    end
  end

  context 'in a new module' do
    include_context 'in a new module', 'new_fact'

    context 'when creating the fact' do
      describe command('pdk new fact new_fact') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{Files added}) }
        its(:stdout) { is_expected.to match(%r{#{File.join('lib', 'facter', 'new_fact.rb')}}) }
        its(:stdout) { is_expected.to match(%r{#{ File.join('spec', 'unit', 'facter', 'new_fact_spec.rb')}}) }
        its(:stderr) { is_expected.to have_no_output }

        it_behaves_like 'it creates a fact',
                        name: 'new_fact',
                        file: File.join('lib', 'facter', 'new_fact.rb'),
                        spec: File.join('spec', 'unit', 'facter', 'new_fact_spec.rb')
      end
    end
  end
end
