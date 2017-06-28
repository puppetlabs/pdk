require 'spec_helper_acceptance'
require 'fileutils'

describe 'Using the test command' do
  context 'not within a module directory' do
    before(:all) do
      Dir.mkdir('not_a_module') || raise
      Dir.chdir('not_a_module')
    end

    after(:all) do
      Dir.chdir('..')
      FileUtils.rm_rf('not_a_module')
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{no metadata\.json found}i) }
    end
  end
end
