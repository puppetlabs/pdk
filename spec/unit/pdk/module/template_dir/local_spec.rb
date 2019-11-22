require 'spec_helper'
require 'pdk/module/template_dir/local'

describe PDK::Module::TemplateDir do
  subject(:template_dir) do
    described_class.with(uri, module_metadata, true) do |foo|
      # block does nothing
    end
  end

  let(:path_or_url) { File.join('/', 'path', 'to', 'templates') }
  let(:uri) { PDK::Util::TemplateURI.new(path_or_url) }

  let(:module_metadata) do
    {
      'name' => 'foo-bar',
      'version' => '0.1.0',
    }
  end

  before(:each) do
    allow(PDK::Util::Git).to receive(:work_tree?).with(path_or_url).and_return(false)
    allow(PDK::Util::Git).to receive(:work_tree?).with(uri.shell_path).and_return(false)
  end

  describe '.metadata' do
    before(:each) do
      allow(PDK::Util::Version).to receive(:version_string).and_return('0.0.0')
      allow(described_class).to receive(:validate_module_template!).with(uri.shell_path).and_return(true)
    end

    context 'with a plain filesystem template directory' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(false)
      end

      context 'pdk data' do
        it 'includes the PDK version and template info' do
          expect(template_dir.metadata).to include('pdk-version' => '0.0.0', 'template-url' => path_or_url, 'template-ref' => nil)
        end
      end
    end
  end
end
