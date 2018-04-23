require 'spec_helper_acceptance'

describe 'puppet version selection' do
  context 'in a new module' do
    include_context 'in a new module', 'version_select'

    %w[5.5.0 4.10.10].each do |puppet_version|
      describe command("pdk validate --puppet-version #{puppet_version}") do
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe file('Gemfile.lock') do
        it { is_expected.to exist }
        its(:content) { is_expected.to match(%r{^\s+puppet \(#{Regexp.escape(puppet_version)}(\)|-)}im) }
      end
    end

    { '2017.3.1' => '5.3.2', '2017.2.1' => '4.10.1' }.each do |pe_version, puppet_version|
      describe command("pdk validate --pe-version #{pe_version}") do
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe file('Gemfile.lock') do
        it { is_expected.to exist }
        its(:content) { is_expected.to match(%r{^\s+puppet \(#{Regexp.escape(puppet_version)}(\)|-)}im) }
      end
    end
  end
end
