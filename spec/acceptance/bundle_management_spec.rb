require 'spec_helper_acceptance'

describe 'Managing Gemfile dependencies' do
  before(:all) do
    system('pdk new module foo --skip-interview') || raise
    Dir.chdir('foo')
  end

  after(:all) do
    Dir.chdir('..')
    FileUtils.rm_rf('foo')
  end

  context 'when there is no Gemfile.lock' do
    before(:all) do
      File.delete('Gemfile.lock') if File.exist?('Gemfile.lock')
      # TODO: come up with a way to invoke only the bundler stuff without trying to run unit tests
      # @result = shell_ex("#{path_to_pdk} ", chdir: target_dir)
    end

    describe command('pdk test unit') do
      its(:exit_status) { pending 'json install requires ruby devkit' if Gem.win_platform?; is_expected.to eq 0 }
      its(:stderr) { is_expected.to match(%r{Checking for missing Gemfile dependencies}i) }

      describe file('Gemfile.lock') do
        it { is_expected.to be_file }
      end
    end
  end

  context 'when there is an invalid Gemfile' do
    before(:all) do
      FileUtils.mv('Gemfile', 'Gemfile.old')
      File.open('Gemfile', 'w') do |f|
        f.puts 'not a gemfile'
      end
    end

    after(:all) do
      FileUtils.mv('Gemfile.old', 'Gemfile')
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.not_to eq 0 }
      its(:stderr) { is_expected.to match(%r{error parsing `gemfile`}i) }
    end
  end
end
