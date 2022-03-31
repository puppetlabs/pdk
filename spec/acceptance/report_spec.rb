require 'spec_helper_acceptance'

describe 'Saves report to a file' do
  context 'with a fresh module' do
    include_context 'in a new module', 'report_foo'

    init_pp = File.join('manifests', 'init.pp')

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts <<-EOS
class report {}
        EOS
      end
    end

    context 'when run interactively' do
      include_context 'with a fake TTY'
      # Tests writing reports to a file
      describe command('pdk validate puppet manifests/init.pp --format=text:report.txt') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to have_no_output }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }

        describe file('report.txt') do
          it { is_expected.to exist }
          # pdk (WARNING): puppet-lint: class not documented (manifests/init.pp:1:1)
          its(:content) { is_expected.to match %r{\(warning\):.*class not documented.*\(#{Regexp.escape(init_pp)}.*\)}i }
        end
      end

      # Tests writing reports to stdout doesn't actually write a file named stdout
      describe command('pdk validate puppet manifests/init.pp --format=text:stdout') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }
        its(:stdout) { is_expected.to match(%r{\(warning\):.*class not documented.*\(#{Regexp.escape(init_pp)}.*\)}i) }

        describe file('stdout') do
          it { is_expected.not_to exist }
        end
      end

      # Tests writing reports to stderr doesn't actually write a file named stderr
      describe command('pdk validate puppet manifests/init.pp --format=text:stderr') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to have_no_output }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }
        its(:stderr) do
          # Due to spinners writing at arbitrary cursor locations, we can't depend on the text
          # being at a the beginning of a line.
          is_expected.to match(%r{\(warning\):.*class not documented.*\(#{Regexp.escape(init_pp)}.*\)}i)
        end

        describe file('stderr') do
          it { is_expected.not_to exist }
        end
      end
    end

    context 'when not run interactively' do
      describe command('pdk validate puppet manifests/init.pp') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{using ruby \d+\.\d+\.\d+}i) }
        its(:stderr) { is_expected.to match(%r{using puppet \d+\.\d+\.\d+}i) }
        its(:stdout) { is_expected.to match(%r{\(warning\):.*class not documented.*\(#{Regexp.escape(init_pp)}.*\)}i) }
      end
    end
  end
end
