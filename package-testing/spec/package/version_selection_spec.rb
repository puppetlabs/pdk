require 'spec_helper_package'

describe 'Test puppet & ruby version selection' do
  module_name = 'version_selection'
  test_cases = [
    { envvar: 'PDK_PUPPET_VERSION', version: '6.21.0', expected_puppet: '6.21', expected_ruby: '2.5.9' },
    { envvar: 'PDK_PUPPET_VERSION', version: '6.23.0', expected_puppet: '6.23', expected_ruby: '2.5.9' },
    { envvar: 'PDK_PUPPET_VERSION', version: '7.18.0', expected_puppet: '7.18', expected_ruby: '2.7.7' },
    { envvar: 'PDK_PUPPET_VERSION', version: '7.20.0', expected_puppet: '7.20', expected_ruby: '2.7.7' },
    { envvar: 'PDK_PE_VERSION', version: '2019.8.7', expected_puppet: '6.23', expected_ruby: '2.5.9' },
    { envvar: 'PDK_PE_VERSION', version: '2021.7.0', expected_puppet: '7.20', expected_ruby: '2.7.7' },
    { envvar: 'PDK_PE_VERSION', version: '2021.7.1', expected_puppet: '7.20', expected_ruby: '2.7.7' },
  ]

  before(:all) do
    command("pdk new module #{module_name} --skip-interview").run
  end

  test_cases.each do |test_case|
    slug = (test_case[:envvar] == 'PDK_PE_VERSION') ? 'PE' : 'Puppet'

    context "Select #{slug} #{test_case[:version]}" do
      let(:env) { { test_case[:envvar] => test_case[:version] } }
      let(:cwd) { module_name }

      let(:expected_puppets) do
        gemspecs = shell("find #{install_dir(true)} -name 'puppet-#{test_case[:expected_puppet]}.*.gemspec'")
        puppet_versions = gemspecs.stdout.lines.map { |r| r[%r{puppet-([\d\.]+)(-.+?)?\.gemspec\Z}, 1] }
        puppet_versions.map { |r| Regexp.escape(r) }.join('|')
      end

      describe command('rm Gemfile.lock; pdk bundle update --local') do
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk bundle exec puppet --version') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{using puppet (#{expected_puppets})}im) }
        its(:stdout) { is_expected.to match(%r{^(#{expected_puppets})$}im) }
      end

      describe command('pdk bundle exec ruby --version') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{using ruby #{Regexp.escape(test_case[:expected_ruby])}[\.0-9]*}im) }
        its(:stdout) { is_expected.to match(%r{^ruby #{Regexp.escape(test_case[:expected_ruby])}[\.0-9]*p}im) }
      end
    end
  end
end
