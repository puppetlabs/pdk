require 'spec_helper'
require 'pdk/context'

describe PDK::Context::Module do
  subject(:context) { described_class.new(module_root, nil) }

  let(:module_root) { File.join(FIXTURES_DIR, 'puppet_module') }

  it 'subclasses PDK::Context::AbstractContext' do
    expect(context).is_a?(PDK::Context::AbstractContext)
  end

  it 'remembers the module root' do
    expect(context.root_path).to eq(module_root)
  end

  describe '.pdk_compatible?' do
    it 'calls PDK::Util to determine compatibility' do
      expect(PDK::Util).to receive(:module_pdk_compatible?).with(context.root_path).and_return(true)
      expect(context.pdk_compatible?).to be(true)
    end
  end
end
