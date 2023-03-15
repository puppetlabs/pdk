require 'spec_helper_acceptance'

describe 'pdk new function', module_command: true do
  shared_examples 'it creates a function' do |_options|
    context 'in a new module' do
      include_context 'in a new module', 'new_function'
      context 'when creating the function' do
        describe command('pdk new function -t v4 abs') do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match(%r{Files added}) }
          its(:stdout) { is_expected.to match(%r{#{File.join('lib', 'puppet', 'functions', 'abs.rb')}}) }
          its(:stdout) { is_expected.to match(%r{#{File.join('dspec', 'functions', 'abs_spec.rb')}}) }
          its(:stderr) { is_expected.to have_no_output }

          it_behaves_like 'it creates a function',
                          name: 'abs',
                          file: File.join('lib', 'puppet', 'functions', 'abs.rb'),
                          spec: File.join('spec', 'functions', 'abs_spec.rb')
        end

        describe command('pdk new function -t native abs') do
          its(:exit_status) { is_expected.to eq 0 }
          its(:stdout) { is_expected.to match(%r{Files added}) }
          its(:stdout) { is_expected.to match(%r{#{File.join('functions', 'abs.pp')}}) }
          its(:stdout) { is_expected.to match(%r{#{File.join('spec', 'functions', 'abs_spec.rb')}}) }
          its(:stderr) { is_expected.to have_no_output }

          it_behaves_like 'it creates a function',
                          name: 'abs',
                          file: File.join('functions', 'abs.rb'),
                          spec: File.join('spec', 'functions', 'abs_spec.rb')
        end
      end
    end
  end
end
