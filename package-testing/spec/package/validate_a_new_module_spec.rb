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
        is_expected.to include('template-url' => a_string_matching(/\Apdk-default#[\w.-]+\Z/))
      end
    end
  end

  # If this test fails with a mismatch between the expected and actual Gemfile.lock content, check that the following
  # steps are up to date:
  # - Ensure that the pdk-templates main has been given an anotated (it must be annotated) tag with the version number,
  #   if between releases add a fourth number to it, i.e. 3.2.0.3
  # - Ensure that the pdk version.rb is pointing to this tag
  #   https://github.com/puppetlabs/pdk/blob/main/lib/pdk/version.rb
  # - Ensure that the pdk-vanagon template pin is up to date with the pdk-templates main commit
  context 'when validating the module' do
    context "with puppet #{PDK_VERSION[:latest][:major]}" do
      let(:ruby_version) { ruby_for_puppet(PDK_VERSION[:latest][:major]) }

      describe command("pdk validate --puppet-version=#{PDK_VERSION[:latest][:major]}") do
        let(:cwd) { module_name }

        its(:exit_status) { is_expected.to eq(0) }
      end

      describe file(File.join(module_name, 'Gemfile.lock')) do
        it { is_expected.to be_file }

        describe 'the content of the file' do
          subject { super().content.gsub(/^DEPENDENCIES.+?\n\n/m, '') }

          it 'is identical to the vendored lockfile' do
            vendored_lockfile = File.join(install_dir, 'share', 'cache', "Gemfile-#{ruby_version}.lock")

            expect(subject).to eq(file(vendored_lockfile).content.gsub(/^DEPENDENCIES.+?\n\n/m, ''))
          end
        end
      end
    end
  end
end
