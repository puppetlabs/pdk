require 'spec_helper_package'

describe 'Generate a module for unit testing' do
  module_name = 'unit_test_module'

  context 'when creating a new module and new class' do
    describe command("pdk new module #{module_name} --skip-interview") do
      its(:exit_status) { is_expected.to eq(0) }
    end

    describe command("pdk new class #{module_name}") do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
    end
  end

  context 'when unit testing' do
    describe command('pdk test unit') do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{evaluated 4 tests.*0 failures}im) }
    end
  end

  context 'when unit testing in parallel' do
    describe command('pdk test unit --parallel') do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{evaluated 4 tests.*0 failures}im) }
    end
  end
end
