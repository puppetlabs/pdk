require 'spec_helper_package'

describe 'Test puppet & ruby version selection' do
  module_name = 'version_selection'
  test_cases = [
    { envvar: 'PDK_PUPPET_VERSION', version: '5.5.0', expected_puppet: '5.5', expected_ruby: '2.4' },
    { envvar: 'PDK_PE_VERSION', version: '2017.3', expected_puppet: '5.3', expected_ruby: '2.4' },
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
