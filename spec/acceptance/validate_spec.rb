require 'spec_helper_acceptance'
require 'tmpdir'
require 'fileutils'

describe 'Running validation' do
  context 'outside of a module' do
    before(:all) do
      Dir.mkdir('empty_test_dir')
      Dir.chdir('empty_test_dir')
    end

    after(:all) do
      Dir.chdir('..')
      FileUtils.rm_rf('empty_test_dir')
    end

    describe command('pdk validate') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{pdk validate must be run inside a module}i) }
      its(:stderr) { is_expected.to match(%r{\A\Z}) }
    end
  end
end
