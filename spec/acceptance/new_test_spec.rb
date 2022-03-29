require 'spec_helper_acceptance'

describe 'pdk new test', module_command: true do
  context 'in a new module' do
    include_context 'in a new module', 'new_unit_test'

    before(:all) do
      File.open(File.join('manifests', 'init.pp'), 'w') do |fd|
        fd.puts 'class new_unit_test {\n}'
      end

      File.open(File.join('manifests', 'def_type.pp'), 'w') do |fd|
        fd.puts 'define new_unit_test::def_type() {\n}'
      end
    end

    context 'when creating a test for the main class' do
      describe command('pdk new test --unit new_unit_test') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{#{File.join('spec', 'classes', 'new_unit_test_spec.rb')}}) }
        its(:stderr) { is_expected.to match(%r{Using Ruby}) }
        its(:stderr) { is_expected.to match(%r{Using Puppet}) }

        describe file(File.join('spec', 'classes', 'new_unit_test_spec.rb')) do
          it { is_expected.to be_file }
          its(:content) do
            is_expected.to match(%r{describe 'new_unit_test' do})
          end
        end
      end
    end

    context 'when creating a test for a defined type' do
      describe command('pdk new test def_type') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{#{File.join('spec', 'defines', 'def_type_spec.rb')}}) }
        its(:stderr) { is_expected.to match(%r{Using Ruby}) }
        its(:stderr) { is_expected.to match(%r{Using Puppet}) }

        describe file(File.join('spec', 'defines', 'def_type_spec.rb')) do
          it { is_expected.to be_file }
          its(:content) do
            is_expected.to match(%r{describe 'new_unit_test::def_type' do})
          end
        end
      end
    end
  end
end
