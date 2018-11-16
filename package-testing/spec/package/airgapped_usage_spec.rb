require 'spec_helper_package'

describe 'Basic usage in an air-gapped environment' do
  module_name = 'airgapped_module'

  def hosts_file
    if windows_node?
      '/cygdrive/c/Windows/System32/Drivers/etc/hosts'
    else
      '/etc/hosts'
    end
  end

  context 'with rubygems.org access disabled' do
    before(:all) do
      shell("cp #{hosts_file} #{hosts_file}.bak")
      shell("echo \"127.0.0.1 rubygems.org\" >> #{hosts_file}")
    end

    after(:all) do
      shell("cp #{hosts_file}.bak #{hosts_file}")
    end

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
    end

    context 'when validating the module' do
      describe command('pdk validate') do
        let(:cwd) { module_name }

        its(:exit_status) { is_expected.to eq(0) }
      end

      describe file(File.join(module_name, 'Gemfile.lock')) do
        it { is_expected.to be_file }

        describe 'the content of the file' do
          subject { super().content.gsub(%r{^DEPENDENCIES.+?\n\n}m, '') }

          it 'is identical to the vendored lockfile' do
            # TODO: Need to find a better way to get 'latest_ruby' programmatically so we can use the correct vendored gemfile.
            vendored_lockfile = File.join(install_dir, 'share', 'cache', 'Gemfile-2.5.1.lock')
            is_expected.to eq(file(vendored_lockfile).content.gsub(%r{^DEPENDENCIES.+?\n\n}m, ''))
          end
        end
      end
    end
  end
end
