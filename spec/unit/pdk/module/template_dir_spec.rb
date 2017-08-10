require 'spec_helper'

describe PDK::Module::TemplateDir do
  subject(:template_dir) do
    described_class.new(path_or_url, module_metadata) do |foo|
      # block does nothing
    end
  end

  let(:path_or_url) { '/path/to/templates' }

  let(:module_metadata) do
    {
      'name' => 'foo-bar',
      'version' => '0.1.0',
    }
  end

  let(:config_defaults) do
    <<-EOS
      ---
      foo:
        attr:
          - val: 1
    EOS
  end

  context 'with a valid template path' do
    it 'returns config hash with module metadata' do
      allow(File).to receive(:directory?).with(anything).and_return(true)
      allow(PDK::Util).to receive(:make_tmpdir_name).with('pdk-module-template').and_return('/tmp/path')
      allow(PDK::CLI::Exec).to receive(:git).with('clone', path_or_url, '/tmp/path').and_return(exit_code: 0)
      allow(File).to receive(:file?).with(anything).and_return(File.join(path_or_url, 'config_defaults.yml')).and_return(true)
      allow(File).to receive(:read).with(File.join(path_or_url, 'config_defaults.yml')).and_return(config_defaults)
      allow(Dir).to receive(:rmdir).with('/tmp/path').and_return(0)

      allow(described_class).to receive(:new).with(path_or_url, module_metadata).and_yield(template_dir)
      expect(template_dir.object_config).to include('module_metadata' => module_metadata)
    end
  end

  it 'has a metadata method' do
    expect(described_class.instance_methods(false)).to include(:metadata)
  end
end
