require 'spec_helper_acceptance'

describe 'puppet version selection' do
  context 'in a new module' do
    include_context 'in a new module', 'version_select'

    %w[PUPPET FACTER HIERA].each do |gem|
      context "when the legacy #{gem}_GEM_VERSION environment variable is used" do
        if Gem.win_platform?
          pre_cmd = "$env:#{gem}_GEM_VERSION='1.0.0';"
          post_cmd = "; remove-item env:\\#{gem}_GEM_VERSION"
        else
          pre_cmd = "#{gem}_GEM_VERSION=1.0.0"
          post_cmd = ''
        end

        describe command("#{pre_cmd} pdk validate#{post_cmd}") do
          its(:exit_status) { is_expected.to eq(0) }
          its(:stderr) { is_expected.to match(%r{#{gem}_GEM_VERSION is not supported by PDK}im) }
        end
      end
    end

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

    describe 'puppet-dev uses the correct puppet env' do
      before(:all) do
        File.open(File.join('manifests', 'init.pp'), 'w') do |f|
          f.puts <<-PPFILE
# version_select
class version_select {
}
          PPFILE
        end

        FileUtils.mkdir_p(File.join('spec', 'classes'))
        File.open(File.join('spec', 'classes', 'version_select_spec.rb'), 'w') do |f|
          f.puts <<-TESTFILE
require 'spec_helper'

describe 'version_select' do
  context 'test env' do
    it('has path') {
      path = Gem::Specification.find_by_name('puppet').source.options.key?('path')
      expect(path).to be true
    }
  end
end
          TESTFILE
        end
      end

      describe command('pdk validate') do
        its(:stderr) { is_expected.not_to match(%r{Using Puppet file://}i) }
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.not_to match(%r{Using Puppet file://}i) }
      end

      describe command('pdk validate --puppet-dev') do
        its(:stderr) { is_expected.to match(%r{Using Puppet file://}i) }
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk test unit --puppet-dev') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{Using Puppet file://}i) }
      end
    end
  end
end
