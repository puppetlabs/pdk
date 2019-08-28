require 'spec_helper'

shared_context :with_puppet_object_module_metadata do
  let(:module_metadata) { '{"name": "testuser-test_module"}' }

  before(:each) do
    allow(File).to receive(:file?).with(metadata_path).and_return(true)
    allow(File).to receive(:readable?).with(metadata_path).and_return(true)
    allow(File).to receive(:read).with(metadata_path).and_return(module_metadata)
  end
end

describe PDK::Generate::PuppetObject do
  let(:templated_object) { described_class.new(module_dir, 'test_module::test_object', options) }

  let(:object_type) { :something }
  let(:options) { {} }
  let(:module_dir) { '/tmp/test_module' }
  let(:metadata_path) { File.join(module_dir, 'metadata.json') }

  before(:each) do
    stub_const('PDK::Generate::PuppetObject::OBJECT_TYPE', object_type)
    allow(PDK::Util).to receive(:package_install?).and_return(false)
    allow(PDK::Util).to receive(:module_root).and_return(module_dir)
    allow(PDK).to receive(:answers).and_return({})
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

  describe '#template_data' do
    it 'needs to be implemented by the subclass' do
      expect {
        templated_object.template_data
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#target_object_path' do
    it 'needs to be implemented by the subclass' do
      expect {
        templated_object.target_object_path
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#target_spec_path' do
    it 'needs to be implemented by the subclass' do
      expect {
        templated_object.target_spec_path
      }.to raise_error(NotImplementedError)
    end
  end

  describe '#module_name' do
    context 'when the module metadata.json is available' do
      include_context :with_puppet_object_module_metadata

      it 'can read the module name from the module metadata' do
        expect(templated_object.module_name).to eq('test_module')
      end
    end

    context 'when the module metadata.json is not available' do
      before(:each) do
        allow(File).to receive(:file?).with(metadata_path).and_return(false)
      end

      it 'raises a fatal error' do
        expect {
          templated_object.module_metadata
        }.to raise_error(PDK::CLI::FatalError, %r{'#{module_dir}'.*not contain.*metadata})
      end
    end
  end

  describe '#render_file' do
    include_context :with_puppet_object_module_metadata

    let(:dest_path) { '/path/to/file/to/be/written' }
    let(:dest_dir) { File.dirname(dest_path) }
    let(:template_path) { '/path/to/file/template' }
    let(:template_data) { { some: 'data', that: 'the', template: 'needs' } }
    let(:template_content) { 'rendered file content' }
    let(:template_file) { instance_double(PDK::TemplateFile, render: template_content) }
    let(:rendered_file) { StringIO.new }

    before(:each) do
      allow(logger).to receive(:info).with(a_string_matching(%r{creating '#{dest_path}' from template}i))
      allow(PDK::TemplateFile).to receive(:new).with(template_path, template_data).and_return(template_file)
      allow(File).to receive(:open).with(any_args).and_call_original
      allow(File).to receive(:open).with(dest_path, 'wb').and_yield(rendered_file)
    end

    it 'creates the parent directories for the destination path if needed' do
      expect(FileUtils).to receive(:mkdir_p).with(dest_dir)
      templated_object.render_file(dest_path, template_path, template_data)
    end

    it 'writes the rendered file content to the destination file' do
      allow(FileUtils).to receive(:mkdir_p).with(dest_dir)
      templated_object.render_file(dest_path, template_path, template_data)
      rendered_file.rewind
      expect(rendered_file.read).to eq(template_content + "\n")
    end

    context 'when it fails to create the parent directories' do
      before(:each) do
        allow(FileUtils).to receive(:mkdir_p).with(dest_dir).and_raise(SystemCallError, 'some message')
      end

      it 'raises a FatalError' do
        expect {
          templated_object.render_file(dest_path, template_path, template_data)
        }.to raise_error(PDK::CLI::FatalError, %r{unable to create directory '.+':.+some message}i)
      end
    end

    context 'when it fails to write the destination file' do
      before(:each) do
        allow(File).to receive(:open).with(dest_path, 'wb').and_raise(SystemCallError, 'some message')
        allow(FileUtils).to receive(:mkdir_p).with(dest_dir)
      end

      it 'raises a FatalError' do
        expect {
          templated_object.render_file(dest_path, template_path, template_data)
        }.to raise_error(PDK::CLI::FatalError, %r{unable to write to file '.+':.+some message}i)
      end
    end
  end

  describe '#with_templates' do
    include_context :with_puppet_object_module_metadata

    let(:default_templatedir) { instance_double('PDK::Module::TemplateDir', 'default') }
    let(:default_object_paths) { { object: 'default_object_path', spec: 'default_spec_path' } }
    let(:configs_hash) { {} }
    let(:cli_templatedir) { instance_double('PDK::Module::TemplateDir', 'CLI') }
    let(:cli_object_paths) { { object: 'cli_object_path', spec: 'cli_spec_path' } }
    let(:metadata_templatedir) { instance_double('PDK::Module::TemplateDir', 'metadata') }
    let(:metadata_object_paths) { { object: 'metadata_object_path', spec: 'metadata_spec_path' } }

    before(:each) do
      allow(default_templatedir).to receive(:object_template_for).with(object_type).and_return(default_object_paths)
      allow(default_templatedir).to receive(:object_config).and_return(configs_hash)
      allow(cli_templatedir).to receive(:object_config).and_return(configs_hash)
      allow(metadata_templatedir).to receive(:object_config).and_return(configs_hash)
      allow(PDK::Module::TemplateDir).to receive(:new).with(any_args).and_yield(default_templatedir)
      allow(PDK::Util).to receive(:development_mode?).and_return(true)
    end

    context 'when a template-url is provided on the CLI' do
      let(:options) { { :'template-url' => '/some/path' } }

      before(:each) do
        allow(PDK::Module::TemplateDir).to receive(:new).with(Addressable::URI.parse('/some/path#master')).and_yield(cli_templatedir)
      end

      context 'and a template for the object type exists' do
        before(:each) do
          allow(cli_templatedir).to receive(:object_template_for).with(object_type).and_return(cli_object_paths)
        end

        it 'yields the path to the object templates from the template dir specified in the CLI' do
          expect { |b| templated_object.with_templates(&b) }.to yield_with_args(cli_object_paths, {})
        end
      end

      context 'and a template for the object type does not exist' do
        before(:each) do
          allow(cli_templatedir).to receive(:object_template_for).with(object_type).and_return(nil)
        end

        it 'raises a fatal error' do
          expect { |b| templated_object.with_templates(&b) }.to raise_error(PDK::CLI::FatalError, %r{Unable to find})
        end
      end
    end

    context 'when a template-url is not provided on the CLI' do
      context 'and a template-url is found in the module metadata' do
        let(:module_metadata) { '{"name": "testuser-test_module", "template-url": "/some/other/path"}' }

        before(:each) do
          allow(PDK::Module::TemplateDir).to receive(:new).with(Addressable::URI.parse('/some/other/path')).and_yield(metadata_templatedir)
        end

        context 'and a template for the object type exists' do
          before(:each) do
            allow(metadata_templatedir).to receive(:object_template_for).with(object_type).and_return(metadata_object_paths)
          end

          it 'yields the path to the object templates from the template dir specified in the metadata' do
            expect { |b| templated_object.with_templates(&b) }.to yield_with_args(metadata_object_paths, {})
          end
        end

        context 'and a template for the object type does not exist' do
          before(:each) do
            allow(metadata_templatedir).to receive(:object_template_for).with(object_type).and_return(nil)
          end

          it 'falls back to the paths from the default template dir' do
            expect(default_templatedir).to receive(:object_template_for).with(object_type)
            templated_object.with_templates {}
          end
        end
      end

      context 'and a template-url is not found in the module metadata' do
        it 'yields the path to the object templates from the default template dir' do
          expect { |b| templated_object.with_templates(&b) }.to yield_with_args(default_object_paths, {})
        end
      end
    end
  end

  describe '#run' do
    include_context :with_puppet_object_module_metadata

    let(:target_object_path) { '/tmp/test_module/object_file' }
    let(:target_spec_path) { '/tmp/test_module/spec_file' }

    before(:each) do
      allow(templated_object).to receive(:target_object_path).and_return(target_object_path)
      allow(templated_object).to receive(:target_spec_path).and_return(target_spec_path)
      allow(templated_object).to receive(:template_data).and_return({})
    end

    context 'when the target files do not exist' do
      let(:object_template) { '/tmp/test_template/object.erb' }
      let(:spec_template) { '/tmp/test_template/spec.erb' }

      before(:each) do
        allow(File).to receive(:exist?).with(target_object_path).and_return(false)
        allow(File).to receive(:exist?).with(target_spec_path).and_return(false)
      end

      it 'renders the object file' do
        expect(templated_object).to receive(:with_templates).and_yield({ object: object_template }, {})
        expect(templated_object).to receive(:render_file).with(target_object_path, object_template, configs: {})
        templated_object.run
      end

      it 'renders the spec file if a template for it was found' do
        expect(templated_object).to receive(:with_templates).and_yield({ object: object_template, spec: spec_template }, {})
        expect(templated_object).to receive(:render_file).with(target_object_path, object_template, configs: {})
        expect(templated_object).to receive(:render_file).with(target_spec_path, spec_template, configs: {})
        templated_object.run
      end
    end

    context 'when the target object file exists' do
      before(:each) do
        allow(File).to receive(:exist?).with(target_spec_path).and_return(false)
        allow(File).to receive(:exist?).with(target_object_path).and_return(true)
      end

      it 'raises an error' do
        expect { templated_object.run }.to raise_error(PDK::CLI::ExitWithError, %r{'#{target_object_path}' already exists})
      end
    end

    context 'when the target spec file exists' do
      before(:each) do
        allow(File).to receive(:exist?).with(target_object_path).and_return(false)
        allow(File).to receive(:exist?).with(target_spec_path).and_return(true)
      end

      it 'raises an error' do
        expect { templated_object.run }.to raise_error(PDK::CLI::ExitWithError, %r{'#{target_spec_path}' already exists})
      end
    end

    context 'when only generating specs' do
      let(:options) { { spec_only: true } }

      context 'when the target spec file exists' do
        before(:each) do
          allow(File).to receive(:exist?).with(target_spec_path).and_return(true)
        end

        it 'raises an error' do
          msg = %r{unable to generate unit test; '#{target_spec_path}' already exists}i
          expect {
            templated_object.run
          }.to raise_error(PDK::CLI::ExitWithError, msg)
        end
      end

      context 'when the target spec file does not exist' do
        let(:object_template) { '/tmp/test_template/object.erb' }
        let(:spec_template) { '/tmp/test_template/spec.erb' }

        before(:each) do
          allow(File).to receive(:exist?).with(target_spec_path).and_return(false)
          allow(templated_object).to receive(:with_templates).and_yield({ object: object_template, spec: spec_template }, {})
        end

        after(:each) do
          templated_object.run
        end

        it 'renders the spec file' do
          expect(templated_object).to receive(:render_file).with(target_spec_path, spec_template, anything)
        end

        it 'does not attempt to render the object' do
          allow(templated_object).to receive(:render_file).with(target_spec_path, anything, anything)
          expect(templated_object).not_to receive(:render_file).with(target_object_path, anything, anything)
        end
      end
    end
  end
end
