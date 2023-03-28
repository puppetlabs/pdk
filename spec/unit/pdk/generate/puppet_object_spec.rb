require 'spec_helper'
require 'pdk/generate/puppet_object'
require 'addressable'

shared_context 'with puppet object module metadata' do
  let(:module_metadata) { '{"name": "testuser-test_module"}' }

  before(:each) do
    allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_path).and_return(true)
    allow(PDK::Util::Filesystem).to receive(:readable?).with(metadata_path).and_return(true)
    allow(PDK::Util::Filesystem).to receive(:read_file).with(metadata_path).and_return(module_metadata)
  end
end

describe PDK::Generate::PuppetObject do
  let(:templated_object) { described_class.new(pdk_context, 'test_module::test_object', options) }

  let(:pdk_context) { PDK::Context::Module.new(module_dir, module_dir) }
  let(:object_type) { :something }
  let(:options) { {} }
  let(:module_dir) { '/tmp/test_module' }
  let(:metadata_path) { File.join(module_dir, 'metadata.json') }

  include_context 'mock configuration'

  before(:each) do
    stub_const('PDK::Generate::PuppetObject::OBJECT_TYPE', object_type)
    allow(PDK::Util).to receive(:package_install?).and_return(false)
    allow(PDK::Util).to receive(:module_root).and_return(module_dir)
  end

  describe '#spec_only?' do
    subject { templated_object.spec_only? }

    context 'when initialised with option :spec_only => true' do
      let(:options) { { spec_only: true } }

      it { is_expected.to be_truthy }
    end

    context 'when initialised with option :spec_only => false' do
      let(:options) { { spec_only: false } }

      it { is_expected.to be_falsey }
    end

    context 'when initialised without a :spec_only option' do
      let(:options) { {} }

      it { is_expected.to be_falsey }
    end
  end

  describe '#friendly_name' do
    it 'needs to be implemented by the subclass' do
      expect {
        templated_object.friendly_name
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#template_files' do
    it 'needs to be implemented by the subclass' do
      expect {
        templated_object.template_files
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#template_data' do
    it 'needs to be implemented by the subclass' do
      expect {
        templated_object.template_data
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#module_name' do
    context 'when the module metadata.json is available' do
      include_context 'with puppet object module metadata'

      it 'can read the module name from the module metadata' do
        expect(templated_object.module_name).to eq('test_module')
      end
    end

    context 'when the module metadata.json is not available' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_path).and_return(false)
      end

      it 'raises a fatal error' do
        expect {
          templated_object.module_name
        }.to raise_error(PDK::CLI::FatalError, %r{'#{metadata_path}'.*not exist})
      end
    end
  end

  describe '#templates' do
    let(:options) { { 'something' => 'setting' } }

    it 'passes throught the objects to TemplateURI' do
      expect(PDK::Util::TemplateURI).to receive(:templates).with(options)
      templated_object.templates
    end
  end

  describe '#with_templates' do
    let(:uri1_template_dir) { PDK::Template::TemplateDir.new(nil, nil, nil, missing_renderer) }

    let(:expected1_template_dir) { PDK::Template::TemplateDir.new(nil, nil, nil, found_renderer) }

    let(:missing_renderer) do
      instance_double(
        PDK::Template::Renderer::AbstractRenderer,
        has_single_item?: false,
      )
    end

    let(:found_renderer) do
      instance_double(
        PDK::Template::Renderer::AbstractRenderer,
        has_single_item?: true,
      )
    end

    RSpec::Matchers.define :uri_of do |expected|
      match do |actual|
        actual.uri.to_s == expected
      end
    end

    before(:each) do
      # Mock required PuppetObject methods
      allow(templated_object).to receive(:friendly_name).and_return('spec_object')
      allow(templated_object).to receive(:template_files).and_return('source' => 'target')
      allow(templated_object).to receive(:templates).and_return(templates)

      allow(PDK::Template).to receive(:with) # An unknown uri will not yield
      allow(PDK::Template).to receive(:with).with(uri_of('expected1'), pdk_context).and_yield(expected1_template_dir)
      allow(PDK::Template).to receive(:with).with(uri_of('uri1'), pdk_context).and_yield(uri1_template_dir)
    end

    context 'when fallback is allowed' do
      let(:templates) do
        [
          { uri: 'uri1', allow_fallback: true },
          { uri: 'expected1', allow_fallback: true },
        ]
      end

      it 'yields the first available template directory' do
        expect { |b| templated_object.with_templates(&b) }.to yield_with_args(expected1_template_dir)
      end
    end

    context 'when fallback is disabled' do
      let(:templates) do
        [
          { uri: 'uri1', allow_fallback: false },
          { uri: 'expected1', allow_fallback: true },
        ]
      end

      it 'raises a fatal error' do
        expect { |b| templated_object.with_templates(&b) }.to raise_error(PDK::CLI::FatalError, %r{Unable to find})
      end
    end
  end

  describe '#can_run?' do
    subject { templated_object.can_run? }

    context 'when check_preconditions raises an error' do
      before(:each) do
        expect(templated_object).to receive(:check_preconditions).and_raise('Mock Error')
      end

      it { is_expected.to be_falsey }
    end

    context 'when check_preconditions does not raise an error' do
      before(:each) do
        expect(templated_object).to receive(:check_preconditions).and_return(nil)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#run' do
    it 'calls sync_changes! on stage_changes' do
      update_manager = PDK::Module::UpdateManager.new
      expect(templated_object).to receive(:stage_changes).and_return(update_manager)
      expect(update_manager).to receive(:sync_changes!)
      templated_object.run
    end
  end

  describe '#stage_changes' do
    include_context 'with puppet object module metadata'

    let(:source_file) { '/tmp/test_module/object_file' }
    let(:target_file) { 'object_file' }
    let(:absolute_target_file) { File.join(module_dir, target_file) }

    let(:template_files) { { source_file => target_file } }
    let(:non_template_files) { {} }
    let(:update_manager) { PDK::Module::UpdateManager.new }
    let(:null_renderer) { PDK::Template::Renderer::AbstractRenderer.new(nil, nil, pdk_context) }
    let(:template_dir) { PDK::Template::TemplateDir.new(nil, nil, pdk_context, null_renderer) }

    before(:each) do
      # Mock required PuppetObject methods
      allow(templated_object).to receive(:template_files).and_return(template_files)
      allow(templated_object).to receive(:template_data).and_return({})
      allow(templated_object).to receive(:friendly_name).and_return('spec_object')
      allow(templated_object).to receive(:non_template_files).and_return(non_template_files)
      # Mock external objects
      allow(templated_object).to receive(:update_manager_instance).and_return(update_manager)
      allow(templated_object).to receive(:with_templates).and_yield(template_dir)
      # Mock rendering of the template file
      allow(template_dir).to receive(:render_single_item).and_return('mock response')
    end

    context 'when the target files do not exist' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:exist?).with(absolute_target_file).and_return(false)
      end

      it 'renders the object file' do
        expect(templated_object.stage_changes(update_manager)).to be_changes
      end
    end

    context 'when the target object file exists' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:exist?).with(absolute_target_file).and_return(true)
      end

      it 'raises an error' do
        expect { templated_object.stage_changes(update_manager) }.to raise_error(PDK::CLI::ExitWithError, %r{'#{absolute_target_file}' already exists})
      end
    end

    context 'when there are non templated files to add' do
      let(:template_files) { {} }
      let(:non_template_files) { { 'additional_file' => 'additional content' } }

      it 'renders the object file' do
        expect(templated_object.stage_changes(update_manager)).to be_changes
      end
    end
  end
end
