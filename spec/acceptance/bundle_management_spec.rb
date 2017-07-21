require 'spec_helper_acceptance'

describe 'Managing Gemfile dependencies' do
  include_context 'in a new module', 'bundle_management'

  context 'when there is no Gemfile.lock' do
    before(:all) do
      File.delete('Gemfile.lock') if File.exist?('Gemfile.lock')
      # TODO: come up with a way to invoke only the bundler stuff without trying to run unit tests
      # @result = shell_ex("#{path_to_pdk} ", chdir: target_dir)
    end

    describe command('pdk test unit --debug') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{Checking for missing Gemfile dependencies}i) }

      describe file('Gemfile.lock') do
        it { is_expected.to be_file }
      end
    end
  end

  context 'when there is an invalid Gemfile' do
    before(:all) do
      FileUtils.mv('Gemfile', 'Gemfile.old', force: true)
      File.open('Gemfile', 'w') do |f|
        f.puts 'not a gemfile'
      end
    end

    after(:all) do
      FileUtils.mv('Gemfile.old', 'Gemfile', force: true)
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.not_to eq 0 }
      its(:stderr) { is_expected.to match(%r{error parsing `gemfile`}i) }
    end
  end
end
