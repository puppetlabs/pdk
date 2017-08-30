require 'tmpdir'
require 'fileutils'

RSpec.shared_examples('it requires running from inside a module', module_command: true) do
  context 'when run outside of a module' do
    before(:all) do
      Dir.mkdir('empty_test_dir')
      Dir.chdir('empty_test_dir')
    end

    after(:all) do
      Dir.chdir('..')
      FileUtils.rm_rf('empty_test_dir')
    end

    describe command(top_level_description) do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(%r{must be run from inside a valid module}i) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
    end
  end
end
