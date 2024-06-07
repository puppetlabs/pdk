require 'spec_helper_package'

describe 'Test puppet & ruby version selection' do
  module_name = 'version_selection'
  test_cases = [
    { envvar: 'PDK_PUPPET_VERSION', expected_puppet: PDK_VERSION[:lts][:major], expected_ruby: PDK_VERSION[:lts][:ruby] },
    { envvar: 'PDK_PUPPET_VERSION', expected_puppet: PDK_VERSION[:latest][:major], expected_ruby: PDK_VERSION[:latest][:ruby] }
  ]

  before(:all) do
    command('pdk new module version_selection --skip-interview').run
  end

  test_cases.each do |test_case|
    context "Select Puppet #{test_case[:expected_puppet]}" do
      let(:env) { { test_case[:envvar] => test_case[:expected_puppet] } }
      let(:cwd) { module_name }

      let(:expected_puppet) { Regexp.escape(test_case[:expected_puppet]) }
      let(:expected_ruby) { Regexp.escape(test_case[:expected_ruby]) }

      describe command('rm Gemfile.lock; pdk bundle update --local') do
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk bundle exec puppet --version') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(/using puppet (#{expected_puppet}\.\d+\.\d+)/im) }
        its(:stdout) { is_expected.to match(/^(#{expected_puppet}\.\d+\.\d+)*/im) }
      end

      describe command('pdk bundle exec ruby --version') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(/using ruby #{expected_ruby}*/im) }
        its(:stdout) { is_expected.to match(/^(#{expected_ruby})*/im) }
      end
    end
  end
end
