require 'spec_helper_acceptance'

describe 'Creating a new class' do
  before(:all) do
    system('pdk new module foo --skip-interview') || raise
    Dir.chdir('foo')
  end

  after(:all) do
    Dir.chdir('..')
    FileUtils.rm_rf('foo')
  end

  context 'when creating the main class' do
    describe command('pdk new class foo') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{Creating .* from template}) }
      its(:stdout) { is_expected.not_to match(%r{WARN|ERR}) }
      # use this weird regex to match for empty string to get proper diff output on failure
      its(:stderr) { is_expected.to match(%r{\A\Z}) }
    end

    describe file('manifests') do
      it { is_expected.to be_directory }
    end

    describe file('manifests/init.pp') do
      it { is_expected.to be_file }
      its(:content) do
        is_expected.to match(%r{class foo})
      end
    end

    describe file('spec/classes/foo_spec.rb') do
      it { is_expected.to be_file }
      its(:content) do
        is_expected.to match(%r{foo})
      end
    end
  end
end
