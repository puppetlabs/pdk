require 'spec_helper_acceptance'

describe 'pdk new fact', :module_command do
  shared_examples 'it creates a fact' do |_options|
    context 'in a new module' do
      include_context 'in a new module', 'new_fact'

      context 'when creating the fact' do
        describe command('pdk new fact new_fact') do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match(/Files added/) }
          its(:stdout) { is_expected.to match(/#{File.join('lib', 'facter', 'new_fact.rb')}/) }
          its(:stdout) { is_expected.to match(/#{File.join('spec', 'unit', 'facter', 'new_fact_spec.rb')}/) }
          its(:stderr) { is_expected.to have_no_output }

          it_behaves_like 'it creates a fact',
                          name: 'new_fact',
                          file: File.join('lib', 'facter', 'new_fact.rb'),
                          spec: File.join('spec', 'unit', 'facter', 'new_fact_spec.rb')
        end
      end
    end
  end
end
