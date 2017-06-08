require 'spec_helper_acceptance'

describe 'Creating a new class' do
  before(:all) do
    shell_ex("#{path_to_pdk} new module foo --skip-interview")
  end

  after(:all) do
    shell_ex('rm -rf foo')
  end

  context 'when creating the main class' do
    describe command("#{path_to_pdk} new class foo") do
      before do
        @old_pwd = Dir.pwd
        Dir.chdir('foo')
      end

      after do
        Dir.chdir(@old_pwd)
      end

      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(/Creating .* from template/) }
      its(:stdout) { is_expected.not_to match(/WARN|ERR/) }
      # use this weird regex to match for empty string to get proper diff output on failure
      its(:stderr) { is_expected.to match(/\A\Z/) }
    end

    describe file('foo/manifests') do
      it { is_expected.to be_directory }
    end

    describe file('foo/manifests/init.pp') do
      it { is_expected.to be_file }
      its(:content) do
        is_expected.to match(/class foo/)
      end
    end

    describe file('foo/spec/classes/foo_spec.rb') do
      it { is_expected.to be_file }
      its(:content) do
        is_expected.to match(/foo/)
      end
    end

  end
end
