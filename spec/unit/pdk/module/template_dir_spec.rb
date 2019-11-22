require 'spec_helper'
require 'yaml'
require 'pdk/module/template_dir'

describe PDK::Module::TemplateDir do
  subject(:template_dir) do
    described_class.with(uri, module_metadata, true) do |foo|
      # block does nothing
    end
  end

  let(:path_or_url) { File.join('/', 'path', 'to', 'templates') }
  let(:uri) { PDK::Util::TemplateURI.new(path_or_url) }
  let(:tmp_path) { File.join('/', 'tmp', 'path') }

  let(:module_metadata) do
    {
      'name' => 'foo-bar',
      'version' => '0.1.0',
    }
  end

  let(:config_defaults) do
    <<-EOS
      appveyor.yml:
        environment:
          PUPPET_GEM_VERSION: "~> 4.0"
      foo:
        attr:
          - val: 1
    EOS
  end

  before(:each) do
    allow(PDK::Util::Git).to receive(:work_tree?).with(path_or_url).and_return(false)
    allow(PDK::Util::Git).to receive(:work_tree?).with(uri.shell_path).and_return(false)
  end

  describe '.with' do
    before(:each) do
      allow(described_class).to receive(:validate_module_template!).with(uri.shell_path).and_return(true)
    end

    context 'when not passed a block' do
      it 'raises an ArgumentError' do
        expect {
          described_class.with(uri, module_metadata)
        }.to raise_error(ArgumentError, %r{must be initialized with a block}i)
      end
    end

    context 'when not initialized with a PDK::Util::TemplateURI' do
      it 'raises an ArgumentError' do
        expect {
          described_class.with(path_or_url, module_metadata) {}
        }.to raise_error(ArgumentError, %r{must be initialized with a PDK::Util::TemplateURI}i)
      end
    end

    context 'with a git based template directory' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(true)
        allow(PDK::Util::Git).to receive(:work_tree?).with(uri.shell_path).and_return(true)
      end

      it 'returns a git based template' do
        expect(template_dir).to be_a(PDK::Module::TemplateDir::Git)
      end
    end

    context 'with a plain filesystem template directory' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(false)
      end

      it 'returns a local based template' do
        expect(template_dir).to be_a(PDK::Module::TemplateDir::Local)
      end
    end
  end

  describe '#validate_module_template!' do
    let(:moduleroot) { File.join(path_or_url, 'moduleroot') }
    let(:moduleroot_init) { File.join(path_or_url, 'moduleroot_init') }

    before(:each) do
      allow(PDK::Util::Filesystem).to receive(:directory?).with(anything).and_return(true)
    end

    context 'when the template path is a directory' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(path_or_url).and_return(true)
      end

      context 'and the template contains a moduleroot directory' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:directory?).with(moduleroot).and_return(true)
        end

        context 'and a moduleroot_init directory' do
          before(:each) do
            allow(PDK::Util::Filesystem).to receive(:directory?).with(moduleroot_init).and_return(true)
          end

          it 'does not raise an error' do
            expect { described_class.with(uri, module_metadata) {} }.not_to raise_error
          end
        end

        context 'but not a moduleroot_init directory' do
          before(:each) do
            allow(PDK::Util::Filesystem).to receive(:directory?).with(moduleroot_init).and_return(false)
          end

          it 'raises an ArgumentError' do
            expect {
              described_class.with(uri, module_metadata) {}
            }.to raise_error(ArgumentError, %r{does not contain a 'moduleroot_init/'})
          end
        end
      end

      context 'and the template does not contain a moduleroot directory' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:directory?).with(moduleroot).and_return(false)
        end

        it 'raises an ArgumentError' do
          expect {
            described_class.with(uri, module_metadata) {}
          }.to raise_error(ArgumentError, %r{does not contain a 'moduleroot/'})
        end
      end
    end

    context 'when the template path is not a directory' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(path_or_url).and_return(false)
        allow(PDK::Util).to receive(:package_install?).and_return(false)
      end

      context 'and it specifies an deprecated built-in template' do
        before(:each) do
          require 'pdk/module/template_dir/git'

          # rubocop:disable RSpec/AnyInstance
          allow(PDK::Util).to receive(:package_install?).and_return(true)
          allow(PDK::Util::Filesystem).to receive(:fnmatch?).with(anything, path_or_url).and_return(true)
          allow(PDK::Util).to receive(:package_cachedir).and_return(File.join('/', 'path', 'to', 'package', 'cachedir'))
          allow_any_instance_of(PDK::Module::TemplateDir::Git).to receive(:clone_template_repo).and_return(path_or_url)
          allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(true)
          allow(PDK::Util::Filesystem).to receive(:rm_rf)
          allow(PDK::Util::Git).to receive(:git).with('--git-dir', anything, 'describe', '--all', '--long', '--always', anything).and_return(stdout: 'ref', exit_code: 0)
          # rubocop:enable RSpec/AnyInstance
        end

        it 'raises an ArgumentError' do
          expect {
            described_class.with(uri, module_metadata) {}
          }.to raise_error(ArgumentError, %r{built-in template has substantially changed})
        end
      end

      it 'raises an ArgumentError' do
        expect {
          described_class.with(uri, module_metadata) {}
        }.to raise_error(ArgumentError, %r{is not a directory})
      end
    end
  end

  context 'with a valid template path' do
    it 'returns config hash with module metadata' do
      allow(PDK::Util::Filesystem).to receive(:directory?).with(anything).and_return(true)
      allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(false)
      allow(PDK::Util).to receive(:make_tmpdir_name).with('pdk-templates').and_return(tmp_path)
      allow(PDK::CLI::Exec).to receive(:git).with('clone', path_or_url, tmp_path).and_return(exit_code: 0)
      allow(PDK::Util::Filesystem).to receive(:file?).with(anything).and_return(File.join(path_or_url, 'config_defaults.yml')).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:read_file).with(File.join(path_or_url, 'config_defaults.yml')).and_return(config_defaults)
      allow(Dir).to receive(:rmdir).with(tmp_path).and_return(0)

      allow(described_class).to receive(:new).with(uri, module_metadata).and_yield(template_dir)
      expect(template_dir.object_config).to include('module_metadata' => module_metadata)
    end
  end

  describe '.files_in_template(dirs)' do
    context 'when passing in an empty directory' do
      let(:dirs) { ['/the/file/is/here'] }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with('/the/file/is/here').and_return true
      end

      it 'returns an empty list' do
        expect(described_class.files_in_template(dirs)).to eq({})
      end
    end

    context 'when passing in a non-existant directory' do
      let(:dirs) { ['/the/file/is/nothere'] }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with('/the/file/is/nothere').and_return false
      end

      it 'raises an error' do
        expect { described_class.files_in_template(dirs) }.to raise_error(ArgumentError, %r{The directory '/the/file/is/nothere' doesn't exist})
      end
    end

    context 'when passing in a directory with a single file' do
      let(:dirs) { ['/here/moduleroot'] }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with('/here/moduleroot').and_return true
        allow(PDK::Util::Filesystem).to receive(:file?).with('/here/moduleroot/filename').and_return true
        allow(PDK::Util::Filesystem).to receive(:glob).with('/here/moduleroot/**/*', File::FNM_DOTMATCH).and_return ['/here/moduleroot/filename']
      end

      it 'returns the file name' do
        expect(described_class.files_in_template(dirs)).to eq('filename' => '/here/moduleroot')
      end
    end

    context 'when passing in a directory with more than one file' do
      let(:dirs) { ['/here/moduleroot'] }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with('/here/moduleroot').and_return true
        allow(PDK::Util::Filesystem).to receive(:file?).with('/here/moduleroot/filename').and_return true
        allow(PDK::Util::Filesystem).to receive(:file?).with('/here/moduleroot/filename2').and_return true
        allow(PDK::Util::Filesystem).to receive(:glob).with('/here/moduleroot/**/*', File::FNM_DOTMATCH).and_return ['/here/moduleroot/filename', '/here/moduleroot/filename2']
      end

      it 'returns both the file names' do
        expect(described_class.files_in_template(dirs)).to eq('filename' => '/here/moduleroot', 'filename2' => '/here/moduleroot')
      end
    end

    context 'when passing in more than one directory with a file' do
      let(:dirs) { ['/path/to/templates/moduleroot', '/path/to/templates/moduleroot_init'] }

      before(:each) do
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
        expect(described_class.files_in_template(dirs)).to eq('filename' => '/path/to/templates/moduleroot',
                                                              'filename2' => '/path/to/templates/moduleroot_init')
      end
    end
  end

  describe '.render(template_files)' do
    before(:each) do
      allow(PDK::Util::Filesystem).to receive(:directory?).with(anything).and_return(true)
      allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(false)
      allow(PDK::Util).to receive(:make_tmpdir_name).with('pdk-templates').and_return(tmp_path)
      allow(PDK::CLI::Exec).to receive(:git).with('clone', path_or_url, tmp_path).and_return(exit_code: 0)
    end

    context 'when passing in a template file' do
      let(:template_file) { instance_double('PDK::TemplateFile', 'filename.erb') }
      let(:template_files) { { 'filename.erb' => 'file/is/here/' } }

      before(:each) do
        allow(described_class).to receive(:config_for).with('filename').and_return true
        allow(PDK::TemplateFile).to receive(:new).with('file/is/here/filename.erb', configs: true).and_return template_file
        allow(template_file).to receive(:render).and_return template_file
        allow(described_class).to receive(:render).and_return('filename.erb' => 'file/is/here/')
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
        allow(described_class).to receive(:render).and_return('filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/here/')
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
        allow(described_class).to receive(:render).and_return('filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/where/')
      end

      it 'renders the template file and returns relevant values' do
        expect(described_class.render(template_files)).to eq('filename.erb' => 'file/is/here/', 'filename2.erb' => 'file/is/where/')
      end
    end
  end

  describe '.config_for(dest_path)' do
    before(:each) do
      allow(Gem).to receive(:win_platform?).and_return(false)
      allow(PDK::Util::Filesystem).to receive(:directory?).with(anything).and_return(true)
      allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(false)
      allow(PDK::Util).to receive(:make_tmpdir_name).with('pdk-templates').and_return(tmp_path)
      allow(PDK::CLI::Exec).to receive(:git).with('clone', path_or_url, tmp_path).and_return(exit_code: 0)
      allow(PDK::Util::Filesystem).to receive(:file?).with(anything).and_return(File.join(path_or_url, 'config_defaults.yml')).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:read_file).with(File.join(path_or_url, 'config_defaults.yml')).and_return(config_defaults)
      allow(PDK::Util::Filesystem).to receive(:readable?).with(File.join(path_or_url, 'config_defaults.yml')).and_return(true)
      allow(YAML).to receive(:safe_load).with(config_defaults, [], [], true).and_return config_hash
    end

    context 'when the module has a valid .sync.yml file' do
      let(:yaml_text) do
        <<-EOF
       appveyor.yml:
         environment:
           PUPPET_GEM_VERSION: "~> 5.0"
       .travis.yml:
         extras:
         - rvm: 2.1.9
       foo:
         attr:
         - val: 3
       .project:
         delete: true
       .gitlab-ci.yml:
         unmanaged: true
       EOF
      end
      let(:yaml_hash) do
        YAML.load(yaml_text) # rubocop:disable Security/YAMLLoad
      end
      let(:config_hash) do
        YAML.load(config_defaults) # rubocop:disable Security/YAMLLoad
      end

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/module/.sync.yml').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:readable?).with('/path/to/module/.sync.yml').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:read_file).with('/path/to/module/.sync.yml').and_return(yaml_text)
        allow(YAML).to receive(:safe_load).with(yaml_text, [], [], true).and_return(yaml_hash)
        allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
      end

      it 'absorbs config' do
        expect(template_dir.config_for(path_or_url)).to eq('module_metadata' => module_metadata,
                                                           'appveyor.yml'    => { 'environment' => { 'PUPPET_GEM_VERSION' => '~> 5.0' } },
                                                           '.travis.yml'     => { 'extras' => [{ 'rvm' => '2.1.9' }] },
                                                           'foo'             => { 'attr' => [{ 'val' => 1 }, { 'val' => 3 }] },
                                                           '.project'        => { 'delete' => true },
                                                           '.gitlab-ci.yml'  => { 'unmanaged' => true })
      end
      context 'contains a knockout prefix' do
        let(:config_defaults) do
          <<-EOS
            appveyor.yml:
              environment:
                PUPPET_GEM_VERSION: "~> 4.0"
            foo:
              attr:
                - val: 1
              ko:
                - valid
                - removed
          EOS
        end
        let(:yaml_text) do
          <<-EOF
         appveyor.yml:
           environment:
             PUPPET_GEM_VERSION: "~> 5.0"
         .travis.yml:
           extras:
           - rvm: 2.1.9
         foo:
           attr:
           - val: 3
           ko:
           - ---removed
         .project:
           delete: true
         .gitlab-ci.yml:
           unmanaged: true
         EOF
        end
        let(:yaml_hash) do
          YAML.load(yaml_text) # rubocop:disable Security/YAMLLoad
        end
        let(:config_hash) do
          YAML.load(config_defaults) # rubocop:disable Security/YAMLLoad
        end

        it 'removes the knocked out options' do
          expect(template_dir.config_for(path_or_url)).to eq('module_metadata' => module_metadata,
                                                             'appveyor.yml'    => { 'environment' => { 'PUPPET_GEM_VERSION' => '~> 5.0' } },
                                                             '.travis.yml'     => { 'extras' => [{ 'rvm' => '2.1.9' }] },
                                                             'foo'             => { 'attr' => [{ 'val' => 1 }, { 'val' => 3 }], 'ko' => ['valid'] },
                                                             '.project'        => { 'delete' => true },
                                                             '.gitlab-ci.yml'  => { 'unmanaged' => true })
        end
      end
    end

    context 'when the module has an invalid .sync.yml file' do
      let(:yaml_text) do
        <<-EOF
       appveyor.yml:
         environment:
           PUPPET_GEM_VERSION: "~> 5.0
       EOF
      end

      let(:config_hash) do
        YAML.load(config_defaults) # rubocop:disable Security/YAMLLoad
      end

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/module/.sync.yml').and_return true
        allow(PDK::Util::Filesystem).to receive(:readable?).with('/path/to/module/.sync.yml').and_return true
        allow(PDK::Util::Filesystem).to receive(:read_file).with('/path/to/module/.sync.yml').and_return yaml_text
        allow(YAML).to receive(:safe_load).with(yaml_text, [], [], true).and_call_original
        allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
      end

      it 'logs a warning' do
        expect(logger).to receive(:warn).with(%r{not a valid yaml file}i)

        template_dir.config_for(path_or_url)
      end

      it 'returns default config' do
        expected = { 'module_metadata' => module_metadata }.merge(config_hash)
        expect(template_dir.config_for(path_or_url)).to eq(expected)
      end
    end
  end

  describe '.metadata' do
    before(:each) do
      allow(PDK::Util::Version).to receive(:version_string).and_return('0.0.0')
      allow(described_class).to receive(:validate_module_template!).with(uri.shell_path).and_return(true)
    end

    context 'with a git based template directory' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(true)
        allow(PDK::Util::Git).to receive(:work_tree?).with(uri.shell_path).and_return(true)
        allow(PDK::Util::Git).to receive(:describe).with(File.join(uri.shell_path, '.git'), Object).and_return('1234abcd')
      end

      context 'pdk data' do
        it 'includes the PDK version and template info' do
          expect(template_dir.metadata).to include('pdk-version' => '0.0.0', 'template-url' => path_or_url, 'template-ref' => '1234abcd')
        end
      end
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

  describe 'custom template' do
    before(:each) do
      allow(PDK::Util::Filesystem).to receive(:directory?).with(anything).and_return(true)
      allow(PDK::Util::Git).to receive(:repo?).with(path_or_url).and_return(true)
      allow(PDK::Util).to receive(:default_template_url).and_return('default-url')
      allow(PDK::Util::TemplateURI).to receive(:default_template_ref).and_return('default-ref')
      allow(PDK::Util).to receive(:make_tmpdir_name).with('pdk-templates').and_return(tmp_path)
      allow(Dir).to receive(:chdir).with(tmp_path).and_yield
      allow(PDK::Util::Git).to receive(:git).with('clone', path_or_url, tmp_path).and_return(exit_code: 0)
      allow(PDK::Util::Git).to receive(:git).with('reset', '--hard', 'default-sha').and_return(exit_code: 0)
      allow(PDK::Util::Filesystem).to receive(:rm_rf).with(tmp_path)
      allow(PDK::Util::Git).to receive(:git).with('--git-dir', anything, 'describe', '--all', '--long', '--always', 'default-sha').and_return(exit_code: 0, stdout: '1234abcd')
      allow(PDK::Util::Git).to receive(:git).with('--work-tree', anything, '--git-dir', anything, 'status', '--untracked-files=no', '--porcelain', anything).and_return(exit_code: 0, stdout: '')
      allow(PDK::Util::Git).to receive(:git).with('ls-remote', '--refs', 'file:///tmp/path', 'default-ref').and_return(exit_code: 0, stdout:
                                                                                                        "default-sha\trefs/heads/default-ref\n" \
                                                                                                        "default-sha\trefs/remotes/origin/default-ref")
      allow(PDK::Util::Version).to receive(:version_string).and_return('0.0.0')
      allow(PDK::Util).to receive(:canonical_path).with(tmp_path).and_return(tmp_path)
      allow(PDK::Util).to receive(:development_mode?).and_return(false)
    end

    context 'pdk data' do
      it 'includes the PDK version and template info' do
        expect(template_dir.metadata).to include('pdk-version' => '0.0.0', 'template-url' => path_or_url, 'template-ref' => '1234abcd')
      end
    end
  end
end
