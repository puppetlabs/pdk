require 'spec_helper_acceptance'

describe 'Saves report to a file' do
  let(:junit_xsd) { File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd') }

  context 'with a fresh module' do
    include_context 'in a new module', 'foo'

    init_pp = File.join('manifests', 'init.pp')

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts <<-EOS
class foo { }
        EOS
      end
    end

    context 'when run interactively' do
      include_context 'with a fake TTY'
      # Tests writing reports to a file
      describe command('pdk validate puppet manifests/init.pp --format=text:report.txt') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{\A\Z}) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }

        describe file('report.txt') do
          it { is_expected.to exist }
          its(:content) { is_expected.to match %r{^warning:.*#{Regexp.escape(init_pp)}.*class not documented} }
        end
      end

      # Tests writing reports to stdout doesn't actually write a file named stdout
      describe command('pdk validate puppet manifests/init.pp --format=text:stdout') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }
        its(:stdout) { is_expected.to match(%r{^warning:.*#{Regexp.escape(init_pp)}.*class not documented}) }

        describe file('stdout') do
          it { is_expected.not_to exist }
        end
      end

      # Tests writing reports to stderr doesn't actually write a file named stderr
      describe command('pdk validate puppet manifests/init.pp --format=text:stderr') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{\A\Z}) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }
        its(:stderr) { is_expected.to match(%r{^warning:.*#{Regexp.escape(init_pp)}.*class not documented}) }

        describe file('stderr') do
          it { is_expected.not_to exist }
        end
      end
    end

    context 'when not run interactively' do
      describe command('pdk validate puppet manifests/init.pp') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{\A\Z}) }
        its(:stdout) { is_expected.to match(%r{^warning:.*#{Regexp.escape(init_pp)}.*class not documented}) }
      end
    end
  end
end
