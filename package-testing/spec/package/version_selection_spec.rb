require 'spec_helper_package'

describe 'Test puppet & ruby version selection' do
  module_name = 'version_selection'
  # IMPORTANT: The following block should be updated with the latest version of each major release supported for the
  # test cases to pass. If you are running integration testing prior to a release and its failing due to missing Puppet
  # gems, verify that the following versions are correct.
  test_cases = [
    { envvar: 'PDK_PUPPET_VERSION', version: '7.26.0', expected_puppet: '7.26.0', expected_ruby: '2.7.8' },
    { envvar: 'PDK_PUPPET_VERSION', version: '8.2.0', expected_puppet: '8.2.0', expected_ruby: '3.2.2' }
  ]

  before(:all) do
    command("pdk new module #{module_name} --skip-interview").run
  end

  test_cases.each do |test_case|
    context "Select Puppet #{test_case[:version]}" do
      let(:env) { { test_case[:envvar] => test_case[:version] } }
      let(:cwd) { module_name }

      let(:expected_puppet) { Regexp.escape(test_case[:expected_puppet]) }
      let(:expected_ruby) { Regexp.escape(test_case[:expected_ruby]) }

      describe command('rm Gemfile.lock; pdk bundle update --local') do
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk bundle exec puppet --version') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(/using puppet (#{expected_puppet})/im) }
        its(:stdout) { is_expected.to match(/^(#{expected_puppet})*/im) }
      end

      describe command('pdk bundle exec ruby --version') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(/using ruby #{expected_ruby}*/im) }
        its(:stdout) { is_expected.to match(/^(#{expected_ruby})*/im) }
      end
    end
  end
end
