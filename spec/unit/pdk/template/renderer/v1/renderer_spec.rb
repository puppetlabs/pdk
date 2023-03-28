require 'spec_helper'
require 'pdk/template/renderer/v1/renderer'

describe PDK::Template::Renderer::V1::Renderer do
  subject(:renderer) { described_class.new(template_root, template_uri, pdk_context) }

  let(:template_root) { '/some/path' }
  let(:template_uri) { PDK::Util::TemplateURI.new(template_root) }
  let(:pdk_context) { PDK::Context::None.new(nil) }

  describe '.render' do
    context 'when rendering a module' do
      subject(:render) { renderer.render(PDK::Template::MODULE_TEMPLATE_TYPE, module_name, render_options) }

      let(:module_name) { 'spec_module' }
      let(:render_options) { {} }
      let(:file_in_template_response1) do
        {
          'manage.erb' => File.join(template_root, 'moduleroot'),
          'unmanaged.erb' => File.join(template_root, 'moduleroot'),
          'delete.erb' => File.join(template_root, 'moduleroot'),
        }
      end

      let(:file_in_template_response2) do
        file_in_template_response1.merge(
          'init.erb' => File.join(template_root, 'moduleroot_init')
        )
      end

      let(:template_file) do
        instance_double(
          PDK::Template::Renderer::V1::TemplateFile,
          render: 'rendered value'
        )
      end

      let(:legacy_template_dir) do
        instance_double(
          PDK::Template::Renderer::V1::LegacyTemplateDir
        )
      end

      before do
        allow(renderer).to receive(:files_in_template).with(['/some/path/moduleroot']).and_return(file_in_template_response1)
        allow(renderer).to receive(:files_in_template).with(['/some/path/moduleroot', '/some/path/moduleroot_init']).and_return(file_in_template_response2)
        allow(renderer).to receive(:new_template_file).with(/manage\.erb/, Hash).and_return(template_file)
        allow(renderer).to receive(:new_template_file).with(/unmanaged\.erb/, Hash).and_return(template_file)
        allow(renderer).to receive(:new_template_file).with(/delete\.erb/, Hash).and_return(template_file)
        allow(renderer).to receive(:new_template_file).with(/init\.erb/, Hash).and_return(template_file)

        # Mock the sync.yml responses
        allow(renderer).to receive(:new_legacy_template_dir).and_return(legacy_template_dir)
        allow(legacy_template_dir).to receive(:config_for).with('manage').and_return({})
        allow(legacy_template_dir).to receive(:config_for).with('unmanaged').and_return('unmanaged' => true)
        allow(legacy_template_dir).to receive(:config_for).with('delete').and_return('delete' => true)
        allow(legacy_template_dir).to receive(:config_for).with('init').and_return({})
      end

      def rendered_files
        result = []
        renderer.render(PDK::Template::MODULE_TEMPLATE_TYPE, module_name, render_options) do |dest_path, dest_content, dest_status|
          result << { dest_path: dest_path, dest_content: dest_content, dest_status: dest_status }
        end
        result
      end

      it 'yields the rendered files' do
        expected_result = [
          { dest_path: 'manage',    dest_content: 'rendered value', dest_status: :manage },
          { dest_path: 'unmanaged', dest_content: nil,              dest_status: :unmanage },
          { dest_path: 'delete',    dest_content: nil,              dest_status: :delete }
        ]
        result = rendered_files

        expect(result).to eq(expected_result)
      end

      context 'and an error occurs during rendering' do
        before do
          allow(template_file).to receive(:render).and_raise(RuntimeError, 'mock error')
        end

        it 'raises a FatalError' do
          expect { rendered_files }.to raise_error(PDK::CLI::FatalError, /Failed to render template/)
        end
      end

      context 'and the option :include_first_time is true' do
        let(:render_options) { { include_first_time: true } }

        it 'yields the rendered files including first time files' do
          expected_result = [
            { dest_path: 'manage',    dest_content: 'rendered value', dest_status: :manage },
            { dest_path: 'unmanaged', dest_content: nil,              dest_status: :unmanage },
            { dest_path: 'delete',    dest_content: nil,              dest_status: :delete },
            { dest_path: 'init',      dest_content: 'rendered value', dest_status: :init }
          ]
          result = rendered_files

          expect(result).to eq(expected_result)
        end
      end
    end
  end

  describe '.has_single_item?' do
    before do
      allow(PDK::Util::Filesystem).to receive(:exist?).with("#{template_root}/object_templates/missing.erb").and_return(false)
      allow(PDK::Util::Filesystem).to receive(:exist?).with("#{template_root}/object_templates/exists.erb").and_return(true)
    end

    it 'returns false for files that do not exist' do
      expect(renderer.has_single_item?('missing.erb')).to be false
    end

    it 'returns true for files that do exist' do
      expect(renderer.has_single_item?('exists.erb')).to be true
    end
  end

  describe '.render_single_item' do
    let(:template_data_hash) { { 'something' => 'value' } }

    context 'given an item that does not exist' do
      let(:item_path) { 'missing.erb' }

      before do
        allow(PDK::Util::Filesystem).to receive(:file?).with("#{template_root}/object_templates/missing.erb").and_return(false)
      end

      it 'returns nil' do
        expect(renderer.render_single_item('missing.erb', template_data_hash)).to be_nil
      end
    end

    context 'given an item that exists' do
      let(:item_path) { 'item.erb' }
      let(:item_content) { 'rendered <%- something %>' }

      let(:template_file) do
        instance_double(
          PDK::Template::Renderer::V1::TemplateFile,
          render: 'rendered value'
        )
      end

      before do
        allow(PDK::Util::Filesystem).to receive(:file?).with("#{template_root}/object_templates/item.erb").and_return(true)
        allow(PDK::Util::Filesystem).to receive(:readable?).with("#{template_root}/object_templates/item.erb").and_return(true)
        allow(PDK::Util::Filesystem).to receive(:read_file).with("#{template_root}/object_templates/item.erb").and_return(item_content)
        allow(renderer).to receive(:new_template_file).with(/item\.erb/, Hash).and_return(template_file) # This is fine
      end

      it 'returns the rendered content' do
        expect(renderer.render_single_item(item_path, template_data_hash)).to eq('rendered value')
      end

      it 'logs a message for the item' do
        expect(PDK.logger).to receive(:debug).with(/Rendering .+item\.erb/)
        renderer.render_single_item(item_path, template_data_hash)
      end
    end

    describe '.files_in_template(dirs)' do
      context 'when passing in an empty directory' do
        let(:dirs) { ['/the/file/is/here'] }

        before do
          allow(PDK::Util::Filesystem).to receive(:directory?).with('/the/file/is/here').and_return true
        end

        it 'returns an empty list' do
          expect(renderer.files_in_template(dirs)).to eq({})
        end
      end

      context 'when passing in a non-existant directory' do
        let(:dirs) { ['/the/file/is/nothere'] }

        before do
          allow(PDK::Util::Filesystem).to receive(:directory?).with('/the/file/is/nothere').and_return false
        end

        it 'raises an error' do
          expect { renderer.files_in_template(dirs) }.to raise_error(ArgumentError, %r{The directory '/the/file/is/nothere' doesn't exist})
        end
      end

      context 'when passing in a directory with a single file' do
        let(:dirs) { ['/here/moduleroot'] }

        before do
          allow(PDK::Util::Filesystem).to receive(:directory?).with('/here/moduleroot').and_return true
          allow(PDK::Util::Filesystem).to receive(:file?).with('/here/moduleroot/filename').and_return true
          allow(PDK::Util::Filesystem).to receive(:glob).with('/here/moduleroot/**/*', File::FNM_DOTMATCH).and_return ['/here/moduleroot/filename']
        end

        it 'returns the file name' do
          expect(renderer.files_in_template(dirs)).to eq('filename' => '/here/moduleroot')
        end
      end

      context 'when passing in a directory with more than one file' do
        let(:dirs) { ['/here/moduleroot'] }

        before do
          allow(PDK::Util::Filesystem).to receive(:directory?).with('/here/moduleroot').and_return true
          allow(PDK::Util::Filesystem).to receive(:file?).with('/here/moduleroot/filename').and_return true
          allow(PDK::Util::Filesystem).to receive(:file?).with('/here/moduleroot/filename2').and_return true
          allow(PDK::Util::Filesystem).to receive(:glob).with('/here/moduleroot/**/*', File::FNM_DOTMATCH).and_return ['/here/moduleroot/filename', '/here/moduleroot/filename2']
        end

        it 'returns both the file names' do
          expect(renderer.files_in_template(dirs)).to eq('filename' => '/here/moduleroot', 'filename2' => '/here/moduleroot')
        end
      end

      context 'when passing in more than one directory with a file' do
        let(:dirs) { ['/path/to/templates/moduleroot', '/path/to/templates/moduleroot_init'] }

        before do
          allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/templates').and_return true
          allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/templates/moduleroot').and_return true
          allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/templates/moduleroot_init').and_return true
          allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/templates/moduleroot/.').and_return false
          allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/templates/moduleroot/filename').and_return true
          allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/templates/moduleroot_init/filename2').and_return true
          allow(PDK::Util::Filesystem).to receive(:glob)
            .with('/path/to/templates/moduleroot/**/*', File::FNM_DOTMATCH)
            .and_return ['/path/to/templates/moduleroot/.', '/path/to/templates/moduleroot/filename']
          allow(PDK::Util::Filesystem).to receive(:glob)
            .with('/path/to/templates/moduleroot_init/**/*', File::FNM_DOTMATCH)
            .and_return ['/path/to/templates/moduleroot_init/filename2']
        end

        it 'returns the file names from both directories' do
          expect(renderer.files_in_template(dirs)).to eq('filename' => '/path/to/templates/moduleroot',
                                                         'filename2' => '/path/to/templates/moduleroot_init')
        end
      end
    end
  end
end
