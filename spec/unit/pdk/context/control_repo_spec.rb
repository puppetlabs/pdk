require 'spec_helper'
require 'pdk/context'

describe PDK::Context::ControlRepo do
  subject(:context) { described_class.new(repo_root, nil) }

  let(:repo_root) { File.join(FIXTURES_DIR, 'control_repo') }

  it 'subclasses PDK::Context::AbstractContext' do
    expect(context).is_a?(PDK::Context::AbstractContext)
  end

  it 'remembers the repo root' do
    expect(context.root_path).to eq(repo_root)
  end

  it 'is PDK compatible' do
    expect(context.pdk_compatible?).to eq(true)
  end
end
