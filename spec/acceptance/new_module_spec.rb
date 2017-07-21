require 'spec_helper_acceptance'

describe 'Creating a new module' do
  context 'when the --skip-interview option is used' do
    after(:all) do
      FileUtils.rm_rf('foo')
    end

    describe command('pdk new module foo --skip-interview') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stderr) { is_expected.to match(%r{Creating new module: foo}) }
      its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
      # use this weird regex to match for empty string to get proper diff output on failure
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
    end

    describe file('foo') do
      it { is_expected.to be_directory }
    end

    describe file('foo/metadata.json') do
      it { is_expected.to be_file }
      its(:content_as_json) do
        is_expected.to include('name' => match(%r{-foo}),
                               'template-ref' => match(%r{master-}),
                               'operatingsystem_support' => include('operatingsystem' => 'Debian',
                                                                    'operatingsystemrelease' => ['8']))
      end
    end
  end
end
