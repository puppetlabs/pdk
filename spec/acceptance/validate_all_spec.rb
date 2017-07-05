require 'spec_helper_acceptance'

describe 'Running all validations' do
  let(:junit_xsd) { File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd') }

  context 'with a fresh module' do
    include_context 'in a new module', 'validate_all'

    init_pp = File.join('manifests', 'init.pp')

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts <<-EOS
# validate_all
class validate_all { }
        EOS
      end
    end

    describe command('pdk validate --list') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{Available validators: metadata, puppet, ruby}i) }
    end

    describe command('pdk validate') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{Running all available validators}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end
  end
end
