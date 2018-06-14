require 'spec_helper_package'

describe 'C100321 - Generate a module and validate it (i.e. ensure bundle install works)' do
  module_name = 'c100321_module'

  context 'when creating a new module' do
    describe command("pdk new module #{module_name} --skip-interview") do
      its(:exit_status) { is_expected.to eq(0) }
    end

    describe file(File.join(module_name, 'metadata.json')) do
      it { is_expected.to be_file }
      its(:content_as_json) do
        is_expected.to include('template-url' => a_string_matching(%r{\Afile://.+pdk-templates\.git\Z}))
      end
    end

    describe file(File.join(module_name, 'Gemfile.lock')) do
      it { is_expected.not_to exist }
    end
  end

  context 'when validating the module' do
    describe command('pdk validate') do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
    end

    describe file(File.join(module_name, 'Gemfile.lock')) do
      it { is_expected.to be_file }

      describe 'the content of the file' do
        subject { super().content }

        it 'is identical to the vendored lockfile' do
          vendored_lockfile = File.join(install_dir, 'share', 'cache', 'Gemfile.lock')
          is_expected.to eq(file(vendored_lockfile).content)
        end
      end
    end
  end
end
