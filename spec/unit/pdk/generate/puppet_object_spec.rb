require 'spec_helper'

describe PDK::Generate::PuppetObject do
  let(:templated_object) { described_class.new(module_dir, 'test_module::test_object', options) }

  let(:object_type) { :something }
  let(:options) { {} }
  let(:module_dir) { '/tmp/test_module' }
  let(:metadata_path) { File.join(module_dir, 'metadata.json') }

  before(:each) do
    stub_const('PDK::Generate::PuppetObject::OBJECT_TYPE', object_type)
  end

  context 'when the module metadata.json is available' do
    let(:module_metadata) { '{"name": "testuser-test_module"}' }

    before(:each) do
      allow(File).to receive(:file?).with(metadata_path).and_return(true)
      allow(File).to receive(:readable?).with(metadata_path).and_return(true)
      allow(File).to receive(:read).with(metadata_path).and_return(module_metadata)
    end

    context '#module_name' do
      it 'can read the module name from the module metadata' do
        expect(templated_object.module_name).to eq('test_module')
      end
    end

    context '#with_templates' do
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
        allow(PDK::Module::TemplateDir).to receive(:new).with(PDK::Generate::Module::DEFAULT_TEMPLATE).and_yield(default_templatedir)
      end

      context 'when a template-url is provided on the CLI' do
        let(:options) { { :'template-url' => '/some/path' } }

        before(:each) do
          allow(PDK::Module::TemplateDir).to receive(:new).with(options[:'template-url']).and_yield(cli_templatedir)
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
            allow(PDK::Module::TemplateDir).to receive(:new).with('/some/other/path').and_yield(metadata_templatedir)
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

    context '#run' do
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
          allow(File).to receive(:exist?).with(target_object_path).and_return(true)
        end

        it 'raises a fatal error' do
          expect { templated_object.run }.to raise_error(PDK::CLI::FatalError, %r{'#{target_object_path}' already exists})
        end
      end

      context 'when the target spec file exists' do
        before(:each) do
          allow(File).to receive(:exist?).with(target_object_path).and_return(false)
          allow(File).to receive(:exist?).with(target_spec_path).and_return(true)
        end

        it 'raises a fatal error' do
          expect { templated_object.run }.to raise_error(PDK::CLI::FatalError, %r{'#{target_spec_path}' already exists})
        end
      end
    end
  end

  context 'when the module metadata.json is not available' do
    it 'raises a fatal error' do
      expect(File).to receive(:file?).with(metadata_path).and_return(false)
      expect { templated_object.module_metadata }.to raise_error(PDK::CLI::FatalError, %r{'#{module_dir}'.*not contain.*metadata})
    end
  end
end
