require 'spec_helper_acceptance'

describe 'Using the test command' do
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
      its(:exit_status) do
        pending 'Test command is currently a stub'
        is_expected.not_to eq 0
      end
      its(:stderr) { is_expected.not_to match(%r{WARN|ERROR|FAIL}i) }
    end
  end
end
