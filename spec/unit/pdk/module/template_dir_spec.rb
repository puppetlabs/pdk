require 'spec_helper'

describe PDK::Module::TemplateDir do
  subject(:template_dir) do
    described_class.new(path_or_url, module_metadata, true) do |foo|
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

  describe '.files_in_template(dirs)' do
    context 'when passing in an empty directory' do
      let(:dirs) { ['/the/file/is/here'] }

      before(:each) do
        allow(Dir).to receive(:exist?).with('/the/file/is/here').and_return true
      end
      it 'returns an empty list' do
        expect(described_class.files_in_template(dirs)).to eq({})
      end
    end

    context 'when passing in a non-existant directory' do
      let(:dirs) { ['/the/file/is/nothere'] }

      before(:each) do
        allow(Dir).to receive(:exists?).with('/the/file/is/nothere').and_return false
      end
      it 'raises an error' do
        expect { described_class.files_in_template(dirs) }.to raise_error(ArgumentError, %r{The directory '%\{dir\}' doesn't exist})
      end
    end

    context 'when passing in a directory with a single file' do
      let(:dirs) { ['/here/moduleroot'] }

      before(:each) do
        allow(Dir).to receive(:exist?).with('/here/moduleroot').and_return true
        allow(File).to receive(:file?).with('/here/moduleroot/filename').and_return true
        allow(Dir).to receive(:glob).with('/here/moduleroot/**/*', File::FNM_DOTMATCH).and_return ['/here/moduleroot/filename']
      end
      it 'returns the file name' do
        expect(described_class.files_in_template(dirs)).to eq('filename' => '/here/moduleroot')
      end
    end

    context 'when passing in a directory with more than one file' do
      let(:dirs) { ['/here/moduleroot'] }

      before(:each) do
        allow(Dir).to receive(:exist?).with('/here/moduleroot').and_return true
        allow(File).to receive(:file?).with('/here/moduleroot/filename').and_return true
        allow(File).to receive(:file?).with('/here/moduleroot/filename2').and_return true
        allow(Dir).to receive(:glob).with('/here/moduleroot/**/*', File::FNM_DOTMATCH).and_return ['/here/moduleroot/filename', '/here/moduleroot/filename2']
      end
      it 'returns both the file names' do
        expect(described_class.files_in_template(dirs)).to eq('filename' => '/here/moduleroot', 'filename2' => '/here/moduleroot')
      end
    end

    context 'when passing in more than one directory with a file' do
      let(:path_or_url) { '/path/to/templates' }
      let(:dirs) { ['/path/to/templates/moduleroot', '/path/to/templates/moduleroot_init'] }

      before(:each) do
        allow(Dir).to receive(:exist?).with('/path/to/templates').and_return true
        allow(Dir).to receive(:exist?).with('/path/to/templates/moduleroot').and_return true
        allow(Dir).to receive(:exist?).with('/path/to/templates/moduleroot_init').and_return true
        allow(File).to receive(:file?).with('/path/to/templates/moduleroot/.').and_return true
        allow(File).to receive(:file?).with('/path/to/templates/moduleroot/filename').and_return true
        allow(File).to receive(:file?).with('/path/to/templates/moduleroot_init/filename2').and_return true
        allow(Dir).to receive(:glob).with('/path/to/templates/moduleroot/**/*', File::FNM_DOTMATCH).and_return ['/path/to/templates/moduleroot/.', '/path/to/templates/moduleroot/filename']
        allow(Dir).to receive(:glob).with('/path/to/templates/moduleroot_init/**/*', File::FNM_DOTMATCH).and_return ['/path/to/templates/moduleroot_init/filename2']
      end
      it 'returns the file names from both directories' do
        expect(described_class.files_in_template(dirs)).to eq('filename' => '/path/to/templates/moduleroot',
                                                              'filename2' => '/path/to/templates/moduleroot_init')
      end
    end
  end

  describe '.render(template_files)' do
    before(:each) do
      allow(File).to receive(:directory?).with(anything).and_return(true)
      allow(PDK::Util).to receive(:make_tmpdir_name).with('pdk-module-template').and_return('/tmp/path')
      allow(PDK::CLI::Exec).to receive(:git).with('clone', path_or_url, '/tmp/path').and_return(exit_code: 0)
    end

    context 'when passing in a template file' do
      let(:template_file) { instance_double('PDK::TemplateFile', 'filename.erb') }
      let(:template_files) { { 'filename.erb' => 'file/is/here/' } }

      before(:each) do
        allow(described_class).to receive(:config_for).with('filename').and_return true
        allow(PDK::TemplateFile).to receive(:new).with('file/is/here/filename.erb', configs: true).and_return template_file
        allow(template_file).to receive(:render).and_return template_file
        allow(described_class).to receive(:render) { { 'filename.erb' => 'file/is/here/' } }
      end
      it 'renders the template file and returns relevant values' do
        expect(described_class.render(template_files)).to eq('filename.erb' => 'file/is/here/')
      end
    end

    context 'when passing in two template files in the same location' do
      let(:template_file) { instance_double('PDK::TemplateFile', 'filename.erb') }
      let(:template_file2) { instance_double('PDK::TemplateFile', 'filename2.erb') }
      let(:template_files) { { 'filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/here/' } }

      before(:each) do
        allow(described_class).to receive(:config_for).with('filename').and_return true
        allow(PDK::TemplateFile).to receive(:new).with('file/is/here/filename.erb', configs: true).and_return template_file
        allow(template_file).to receive(:render).and_return template_file
        allow(described_class).to receive(:config_for).with('filename2').and_return true
        allow(PDK::TemplateFile).to receive(:new).with('file/is/here/filename2.erb', configs: true).and_return template_file
        allow(template_file).to receive(:render).and_return template_file2
        allow(described_class).to receive(:render) { { 'filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/here/' } }
      end
      it 'renders the template file and returns relevant values' do
        expect(described_class.render(template_files)).to eq('filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/here/')
      end
    end

    context 'when passing in two template files in different directories' do
      let(:template_file) { instance_double('PDK::TemplateFile', 'filename.erb') }
      let(:template_file2) { instance_double('PDK::TemplateFile', 'filename2.erb') }
      let(:template_files) { { 'filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/here/' } }

      before(:each) do
        allow(described_class).to receive(:config_for).with('filename').and_return true
        allow(PDK::TemplateFile).to receive(:new).with('file/is/here/filename.erb', configs: true).and_return template_file
        allow(template_file).to receive(:render).and_return template_file
        allow(described_class).to receive(:config_for).with('filename2').and_return true
        allow(PDK::TemplateFile).to receive(:new).with('file/is/where/filename2.erb', configs: true).and_return template_file
        allow(template_file2).to receive(:render).and_return template_file2
        allow(described_class).to receive(:render) { { 'filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/where/' } }
      end
      it 'renders the template file and returns relevant values' do
        expect(described_class.render(template_files)).to eq('filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/where/')
      end
    end
  end
end
