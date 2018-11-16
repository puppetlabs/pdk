require 'spec_helper_package'

describe 'C100545 - Generate a module, add a gem to it, and validate it' do
  module_name = 'c100545_module'

  describe command("pdk new module #{module_name} --skip-interview") do
    its(:exit_status) { is_expected.to eq(0) }
  end

  context 'when a new gem dependency has been added to the Gemfile' do
    before(:all) do
      shell("echo \"gem \'nothing\'\" >> #{File.join(module_name, 'Gemfile')}")
    end

    describe command('pdk validate') do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
    end

    describe file(File.join(module_name, 'Gemfile.lock')) do
      it { is_expected.to exist }

      describe 'the content of the file' do
        subject { super().content }

        it 'differs from the vendored lockfile' do
          vendored_lockfile = File.join(install_dir, 'share', 'cache', 'Gemfile.lock')
          is_expected.not_to eq(file(vendored_lockfile).content)
        end
      end
    end
  end
end
