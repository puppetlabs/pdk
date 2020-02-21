require 'spec_helper'
require 'pdk/context'

describe PDK::Context::ControlRepo do
  subject(:context) { described_class.new(repo_root, nil) }

  let(:repo_root) { File.join(FIXTURES_DIR, 'control_repo') }
  let(:expected_module_paths) { ['modules', 'site', '$basemodulepath'] }
  let(:module_paths_in_fixture) { ['site'] }

  it 'subclasses PDK::Context::AbstractContext' do
    expect(context).is_a?(PDK::Context::AbstractContext)
  end

  it 'remembers the repo root' do
    expect(context.root_path).to eq(repo_root)
  end

  it 'is PDK compatible' do
    expect(context.pdk_compatible?).to eq(true)
  end

  describe '.module_paths' do
    it 'returns an array of paths' do
      expect(context.module_paths).to eq(expected_module_paths)
    end

    it 'is memoized' do
      expect(context).to receive(:environment_conf).and_call_original # rubocop:disable RSpec/SubjectStub We are still calling the original so this is fine

      context.module_paths
      context.module_paths
      context.module_paths
    end
  end

  describe '.actualized_module_paths' do
    it 'returns absolute paths that exist on disk' do
      expect(context.actualized_module_paths).to eq(module_paths_in_fixture)
    end

    it 'is memoized' do
      expect(context).to receive(:module_paths).and_call_original # rubocop:disable RSpec/SubjectStub We are still calling the original so this is fine

      context.actualized_module_paths
      context.actualized_module_paths
      context.actualized_module_paths
    end
  end
end
