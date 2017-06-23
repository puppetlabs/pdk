require 'spec_helper_acceptance'

describe 'pdk test unit', module_command: true do
  context 'within a module directory' do
    before(:all) do
      system('pdk new module foo --skip-interview') || raise
      Dir.chdir('foo')
    end

    after(:all) do
      Dir.chdir('..')
      FileUtils.rm_rf('foo')
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{Running unit tests}) }
      its(:stderr) { is_expected.not_to match(%r{WARN|ERROR|FAIL}i) }
    end
  end
end
