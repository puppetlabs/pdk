require 'spec_helper'
require 'tempfile'
require 'stringio'
require 'tty/test_prompt'
require 'pdk/generate/module'

shared_context 'blank answer file' do
  let(:temp_answer_file) { Tempfile.new('pdk-test-answers') }

  before(:each) do
    PDK.answer_file = temp_answer_file.path
  end

  after(:each) do
    temp_answer_file.close
    temp_answer_file.unlink
  end
end

shared_context 'allow summary to be printed to stdout' do
  before(:each) do
    allow($stdout).to receive(:puts).with(a_string_matching(%r{\A-+\Z}))
    allow($stdout).to receive(:puts).with('SUMMARY')
    allow($stdout).to receive(:puts).with(a_string_matching(%r{\A\{.+\}\Z}m))
    allow($stdout).to receive(:puts).with(no_args)
  end
end

shared_context 'mock template dir' do
  let(:test_template_dir) { instance_double(PDK::Module::TemplateDir, metadata: {}) }
  let(:test_template_file) { StringIO.new }

  before(:each) do
    allow(PDK::Module::TemplateDir).to receive(:new).with(anything, anything, anything).and_yield(test_template_dir)

    dir_double = instance_double(Pathname, mkpath: true, to_path: '/a/path')
    allow(dir_double).to receive(:+).with(anything).and_return(dir_double)
    allow(dir_double).to receive(:dirname).and_return(dir_double)
    allow(dir_double).to receive(:relative?).and_return(true)
    allow(Pathname).to receive(:new).with(anything).and_return(dir_double)
    allow(File).to receive(:open).with(dir_double, 'wb').and_yield(test_template_file)
    allow(PDK::Util::Git).to receive(:repo?).with(anything).and_return(true)
  end
end

shared_context 'mock metadata.json' do
  let(:metadata_json) { StringIO.new }

  before(:each) do
    allow(File).to receive(:open).with(a_string_matching(%r{metadata\.json\Z}), 'wb').and_yield(metadata_json)
  end
end

describe PDK::Generate::Module do
  describe '.invoke' do
    before(:each) do
      allow(File).to receive(:open).with(any_args).and_call_original
    end

    let(:target_dir) { File.expand_path('/path/to/target/module') }
    let(:invoke_opts) do
      {
        :target_dir       => target_dir,
        :module_name      => 'foo',
        :'skip-interview' => true,
      }
    end

    before(:each) do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!)
      allow(Dir).to receive(:chdir).with(target_dir).and_yield
    end

    context 'when the target module directory already exists' do
      it 'raises a FatalError' do
        allow(File).to receive(:exist?).with(target_dir).and_return(true)
        expect(logger).not_to receive(:info).with(a_string_matching(%r{generated at path}i))
        expect(logger).not_to receive(:info).with(a_string_matching(%r{In your new module directory, add classes with the 'pdk new class' command}i))

        expect {
          described_class.invoke(module_name: 'foo', target_dir: target_dir)
        }.to raise_error(PDK::CLI::ExitWithError, %r{destination directory '.+' already exists}i)
      end
    end

    context 'when the target module directory does not exist' do
      include_context 'blank answer file'
      include_context 'mock template dir'
      include_context 'mock metadata.json'

      let(:temp_target_dir) { '/path/to/temp/dir' }
      let(:target_parent_writeable) { true }

      before(:each) do
        allow(File).to receive(:exist?).with(target_dir).and_return(false)
        allow(PDK::Util).to receive(:make_tmpdir_name).with(anything).and_return(temp_target_dir)
        allow(FileUtils).to receive(:mv).with(temp_target_dir, target_dir)
        allow(PDK::Util::Version).to receive(:version_string).and_return('0.0.0')
        allow(described_class).to receive(:prepare_module_directory).with(temp_target_dir)
        allow(File).to receive(:open).with(%r{pdk-test-writable}, anything) { raise Errno::EACCES unless target_parent_writeable }
        allow(FileUtils).to receive(:rm_f).with(%r{pdk-test-writable})
        allow(test_template_dir).to receive(:render).and_yield('test_file_path', 'test_file_content', :manage)
      end

      context 'when the parent directory of the target is not writable' do
        let(:target_parent_writeable) { false }

        it 'raises a FatalError' do
          expect(logger).not_to receive(:info).with(a_string_matching(%r{generated at path}i))
          expect(logger).not_to receive(:info).with(a_string_matching(%r{In your new module directory, add classes with the 'pdk new class' command}i))

          expect {
            described_class.invoke(invoke_opts)
          }.to raise_error(PDK::CLI::FatalError, %r{you do not have permission to write to}i)
        end
      end

      it 'generates the new module in a temporary directory' do
        expect(described_class).to receive(:prepare_module_directory).with(temp_target_dir)
        described_class.invoke(invoke_opts)
      end

      context 'when the module template contains template files' do
        let(:content) { 'test_file_content' }

        before(:each) do
          allow(test_template_dir).to receive(:render).and_yield('test_file_path', content, :manage)
        end

        it 'writes the rendered files from the template to the temporary directory' do
          described_class.invoke(invoke_opts)

          test_template_file.rewind
          expect(test_template_file.read).to eq(content + "\n")
        end
      end

      context 'when the module template contains unmanaged template files' do
        let(:content) { 'test_file_content' }

        before(:each) do
          allow(test_template_dir).to receive(:render).and_yield('test_file_path', content, :unmanage)
        end

        it 'writes the rendered files from the template to the temporary directory' do
          described_class.invoke(invoke_opts)

          test_template_file.rewind
          expect(test_template_file.read).to eq(content + "\n")
        end
      end

      context 'when the module template contains files with delete option set' do
        let(:content) { 'test_file_content' }

        before(:each) do
          allow(test_template_dir).to receive(:render).and_yield('test_file_path', content, :delete)
        end

        it 'does not writes the deleted files from the template to the temporary directory' do
          described_class.invoke(invoke_opts)

          test_template_file.rewind
          expect(test_template_file.read).to eq('')
        end
      end

      context 'when the template dir generates metadata about itself' do
        let(:template_metadata) do
          {
            'template-url' => 'test_template_url',
            'template-ref' => 'test_template_ref',
          }
        end

        before(:each) do
          allow(test_template_dir).to receive(:metadata).and_return(template_metadata)
        end

        it 'includes details about the template in the generated metadata.json' do
          described_class.invoke(invoke_opts)

          metadata_json.rewind
          expect(JSON.parse(metadata_json.read)).to include(template_metadata)
        end
      end

      it 'moves the temporary directory to the target directory when done' do
        expect(FileUtils).to receive(:mv).with(temp_target_dir, target_dir)
        described_class.invoke(invoke_opts)
      end

      it 'prepares the bundler environment so that it is ready immediately' do
        allow(FileUtils).to receive(:mv).with(temp_target_dir, target_dir).and_return(true)
        expect(PDK::Util::Bundler).to receive(:ensure_bundle!)
        described_class.invoke(invoke_opts)
      end

      context 'when the move to the target directory fails due to invalid permissions' do
        before(:each) do
          allow(FileUtils).to receive(:mv).with(temp_target_dir, target_dir).and_raise(Errno::EACCES, 'permission denied')
        end

        it 'raises a FatalError' do
          expect(logger).not_to receive(:info).with(a_string_matching(%r{generated at path}i))
          expect(logger).not_to receive(:info).with(a_string_matching(%r{In your new module directory, add classes with the 'pdk new class' command}i))

          expect {
            described_class.invoke(invoke_opts)
          }.to raise_error(PDK::CLI::FatalError, %r{failed to move .+: permission denied}i)
        end
      end

      context 'when a template-url is supplied on the command line' do
        before(:each) do
          allow(FileUtils).to receive(:mv).with(temp_target_dir, target_dir).and_return(0)
          allow(PDK::Util).to receive(:default_template_uri).and_return(Addressable::URI.parse('https://github.com/puppetlabs/pdk-templates'))
        end

        it 'uses that template to generate the module' do
          expect(PDK::Module::TemplateDir).to receive(:new).with(Addressable::URI.parse('cli-template#master'), anything, anything).and_yield(test_template_dir)
          expect(logger).to receive(:info).with(a_string_matching(%r{generated at path}i))
          expect(logger).to receive(:info).with(a_string_matching(%r{In your module directory, add classes with the 'pdk new class' command}i))

          described_class.invoke(invoke_opts.merge(:'template-url' => 'cli-template'))
        end

        it 'takes precedence over the template-url answer' do
          PDK.answers.update!('template-url' => 'answer-template')
          expect(PDK::Module::TemplateDir).to receive(:new).with(Addressable::URI.parse('cli-template#master'), anything, anything).and_yield(test_template_dir)
          described_class.invoke(invoke_opts.merge(:'template-url' => 'cli-template'))
        end

        it 'saves the template-url and template-ref to the answer file if it is not the default template' do
          expect(PDK.answers).to receive(:update!).with('template-url' => Addressable::URI.parse('cli-template#master'))

          described_class.invoke(invoke_opts.merge(:'template-url' => 'cli-template'))
        end

        it 'clears the saved template-url answer if it is the default template' do
          expect(PDK.answers).to receive(:update!).with('template-url' => nil).and_call_original

          described_class.invoke(invoke_opts.merge(:'template-url' => 'https://github.com/puppetlabs/pdk-templates'))
          expect(PDK.answers['template-url']).to eq(nil)
        end
      end

      context 'when a template-url is not supplied on the command line' do
        before(:each) do
          allow(FileUtils).to receive(:mv).with(temp_target_dir, target_dir).and_return(0)
          allow(PDK::Util).to receive(:development_mode?).and_return(true)
        end

        context 'and a template-url answer exists' do
          it 'uses the template-url from the answer file to generate the module' do
            PDK.answers.update!('template-url' => 'answer-template')
            expect(PDK::Module::TemplateDir).to receive(:new).with(Addressable::URI.parse('answer-template'), anything, anything).and_yield(test_template_dir)
            expect(logger).to receive(:info).with(a_string_matching(%r{generated at path}i))
            expect(logger).to receive(:info).with(a_string_matching(%r{In your module directory, add classes with the 'pdk new class' command}i))

            described_class.invoke(invoke_opts)
          end
        end

        context 'and no template-url answer exists' do
          context 'and pdk is installed from packages' do
            before(:each) do
              allow(PDK::Util).to receive(:package_install?).and_return(true)
              allow(PDK::Util).to receive(:package_cachedir).and_return('/tmp/package/cache')
            end

            it 'uses the vendored template url' do
              template_uri = "file:///tmp/package/cache/pdk-templates.git##{PDK::Util::TemplateURI.default_template_ref}"
              expect(PDK::Module::TemplateDir).to receive(:new).with(Addressable::URI.parse(template_uri), anything, anything).and_yield(test_template_dir)
              expect(PDK.answers).not_to receive(:update!).with(:'template-url' => anything)

              described_class.invoke(invoke_opts)
            end
          end

          context 'and pdk is not installed from packages' do
            before(:each) do
              allow(PDK::Util).to receive(:package_install?).and_return(false)
            end

            it 'uses the default template to generate the module' do
              expect(PDK::Module::TemplateDir).to receive(:new).with(any_args).and_yield(test_template_dir)
              expect(PDK.answers).not_to receive(:update!).with(:'template-url' => anything)

              described_class.invoke(invoke_opts)
            end
          end
        end
      end
    end
  end

  describe '.module_interview' do
    include_context 'blank answer file'

    subject(:interview_metadata) do
      metadata = PDK::Module::Metadata.new
      metadata.update!(default_metadata)
      described_class.module_interview(metadata, options)
      metadata.data
    end

    subject(:answers) do
      interview_metadata
      PDK.answers
    end

    let(:module_name) { 'bar' }
    let(:default_metadata) { {} }
    let(:options) { { module_name: module_name } }

    before(:each) do
      prompt = TTY::TestPrompt.new
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
      prompt.input << responses.join("\r") + "\r"
      prompt.input.rewind

      allow($stdout).to receive(:puts).with(a_string_matching(%r{manually updating the metadata.json file}m))
      allow($stdout).to receive(:puts).with(a_string_matching(%r{ask you \d+ questions}))
      allow($stdout).to receive(:puts).with(no_args)
    end

    context 'when only interviewing for specific missing fields' do
      let(:options) do
        { only_ask: ['source'] }
      end

      let(:default_metadata) do
        {
          'name' => 'test-module',
        }
      end

      let(:responses) do
        [
          'https://something',
          'yes',
        ]
      end

      before(:each) do
        allow(File).to receive(:file?).with('metadata.json').and_return(true)
      end

      it 'populates the metadata object based on user input' do
        expected_metadata = PDK::Module::Metadata.new.update!(default_metadata).data.dup
        expected_metadata['source'] = 'https://something'

        expect(interview_metadata).to eq(expected_metadata)
      end

      context 'and the module name contains underscores' do
        let(:default_metadata) do
          {
            'name' => 'test-long_module_name',
          }
        end

        it 'does not reinterview for the module name' do
          expected_metadata = PDK::Module::Metadata.new.update!(default_metadata).data.dup
          expected_metadata['source'] = 'https://something'

          expect(interview_metadata).to eq(expected_metadata)
        end
      end
    end

    context 'with --full-interview' do
      let(:options) { { :module_name => module_name, :'full-interview' => true } }

      context 'when provided answers to all the questions' do
        include_context 'allow summary to be printed to stdout'

        let(:responses) do
          [
            'foo',
            '2.2.0',
            'William Hopper',
            'Apache-2.0',
            '',
            'A simple module to do some stuff.',
            'github.com/whopper/bar',
            'forge.puppet.com/whopper/bar',
            'tickets.foo.com/whopper/bar',
            'yes',
          ]
        end

        before(:each) do
          allow(File).to receive(:file?).with('metadata.json').and_return(false)
        end

        it 'populates the Metadata object based on user input' do
          expect(interview_metadata).to include(
            'name'                    => 'foo-bar',
            'version'                 => '2.2.0',
            'author'                  => 'William Hopper',
            'license'                 => 'Apache-2.0',
            'summary'                 => 'A simple module to do some stuff.',
            'source'                  => 'github.com/whopper/bar',
            'project_page'            => 'forge.puppet.com/whopper/bar',
            'issues_url'              => 'tickets.foo.com/whopper/bar',
            'operatingsystem_support' => [
              {
                'operatingsystem'        => 'CentOS',
                'operatingsystemrelease' => ['7'],
              },
              {
                'operatingsystem'        => 'OracleLinux',
                'operatingsystemrelease' => ['7'],
              },
              {
                'operatingsystem'        => 'RedHat',
                'operatingsystemrelease' => ['8'],
              },
              {
                'operatingsystem'        => 'Scientific',
                'operatingsystemrelease' => ['7'],
              },
              {
                'operatingsystem'        => 'Debian',
                'operatingsystemrelease' => ['9'],
              },
              {
                'operatingsystem'        => 'Ubuntu',
                'operatingsystemrelease' => ['18.04'],
              },
              {
                'operatingsystem'        => 'windows',
                'operatingsystemrelease' => %w[2019 10],
              },
            ],
          )
        end

        it 'saves the forge username to the answer file' do
          expect(answers['forge_username']).to eq('foo')
        end

        it 'saves the module author to the answer file' do
          expect(answers['author']).to eq('William Hopper')
        end

        it 'saves the license to the answer file' do
          expect(answers['license']).to eq('Apache-2.0')
        end
      end

      context 'when the user chooses the default values for everything' do
        include_context 'allow summary to be printed to stdout'

        let(:options) { { :module_name => 'bar', :username => 'defaultauthor', :'full-interview' => true } }
        let(:default_metadata) do
          {
            'author'  => 'defaultauthor',
            'version' => '0.0.1',
            'summary' => 'default summary',
            'source'  => 'default source',
            'license' => 'default license',
          }
        end

        let(:responses) do
          [
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
          ]
        end

        it 'populates the interview question defaults with existing metadata values' do
          expect(interview_metadata).to include(
            'name'    => 'defaultauthor-bar',
            'version' => '0.0.1',
            'author'  => 'defaultauthor',
            'license' => 'default license',
            'summary' => 'default summary',
            'source'  => 'default source',
          )
        end

        it 'saves the forge username to the answer file' do
          expect(answers['forge_username']).to eq('defaultauthor')
        end

        it 'saves the module author to the answer file' do
          expect(answers['author']).to eq('defaultauthor')
        end

        it 'saves the license to the answer file' do
          expect(answers['license']).to eq('default license')
        end
      end
    end

    context 'when there is no module_name provided' do
      include_context 'allow summary to be printed to stdout'

      let(:options) { { license: 'MIT' } }
      let(:responses) do
        [
          'mymodule',
          'myforgename',
          'William Hopper',
          '',
          'yes',
        ]
      end

      it 'populates the Metadata object based on user input for both module name and forge name' do
        expect(interview_metadata).to include(
          'name'         => 'myforgename-mymodule',
          'version'      => '0.1.0',
          'author'       => 'William Hopper',
          'license'      => 'MIT',
          'summary'      => '',
          'source'       => '',
          'project_page' => nil,
          'issues_url'   => nil,
        )
      end
    end

    context 'when the user provides the license as a command line option' do
      include_context 'allow summary to be printed to stdout'

      let(:options) { { module_name: module_name, license: 'MIT' } }
      let(:responses) do
        [
          'foo',
          'William Hopper',
          '',
          'yes',
        ]
      end

      it 'populates the Metadata object based on user input' do
        expect(interview_metadata).to include(
          'name'         => 'foo-bar',
          'version'      => '0.1.0',
          'author'       => 'William Hopper',
          'license'      => 'MIT',
          'summary'      => '',
          'source'       => '',
          'project_page' => nil,
          'issues_url'   => nil,
        )
      end

      it 'saves the forge username to the answer file' do
        expect(answers['forge_username']).to eq('foo')
      end

      it 'saves the module author to the answer file' do
        expect(answers['author']).to eq('William Hopper')
      end

      it 'saves the license to the answer file' do
        expect(answers['license']).to eq('MIT')
      end
    end

    context 'when the user cancels the interview' do
      let(:responses) do
        [
          "foo\003", # \003 being the equivalent to the user hitting Ctrl-C
        ]
      end

      it 'exits cleanly' do
        allow(logger).to receive(:info).with(a_string_matching(%r{interview cancelled}i))
        expect { interview_metadata }.to exit_zero
      end
    end

    context 'when the user does not confirm the metadata' do
      include_context 'allow summary to be printed to stdout'

      let(:responses) do
        [
          'foo',
          'William Hopper',
          'Apache-2.0',
          '',
          'no',
        ]
      end

      it 'exits cleanly' do
        allow(logger).to receive(:info).with(a_string_matching(%r{Process cancelled; exiting.}i))
        expect { interview_metadata }.to exit_zero
      end
    end

    context 'when the user does not confirm with yes or no' do
      include_context 'allow summary to be printed to stdout'

      let(:responses) do
        [
          'foo',
          'William Hopper',
          'Apache-2.0',
          '',
          'test', # incorrect confirmation
          'yes',  # reattempted confirmation
        ]
      end

      it 'reattempts the confirmation' do
        allow($stdout).to receive(:puts).and_call_original
        expect { interview_metadata }.not_to raise_error

        expect(interview_metadata).to include(
          'name'         => 'foo-bar',
          'version'      => '0.1.0',
          'author'       => 'William Hopper',
          'license'      => 'Apache-2.0',
          'summary'      => '',
          'source'       => '',
          'project_page' => nil,
          'issues_url'   => nil,
        )
      end
    end

    context 'when the user selects operating systems' do
      include_context 'allow summary to be printed to stdout'

      let(:responses) do
        [
          'foo',
          'William Hopper',
          'Apache-2.0',
          "\e[A 1 ", # \e[A == up arrow
          'yes',
        ]
      end

      it 'includes the modified operatingsystem_support value in the metadata' do
        allow($stdout).to receive(:puts).and_call_original
        expect { interview_metadata }.not_to raise_error

        expect(interview_metadata).to include(
          'name'         => 'foo-bar',
          'version'      => '0.1.0',
          'author'       => 'William Hopper',
          'license'      => 'Apache-2.0',
          'summary'      => '',
          'source'       => '',
          'project_page' => nil,
          'issues_url'   => nil,
          'operatingsystem_support' => [
            {
              'operatingsystem'        => 'Debian',
              'operatingsystemrelease' => ['9'],
            },
            {
              'operatingsystem'        => 'Ubuntu',
              'operatingsystemrelease' => ['18.04'],
            },
            {
              'operatingsystem'        => 'windows',
              'operatingsystemrelease' => %w[2019 10],
            },
            {
              'operatingsystem'        => 'Solaris',
              'operatingsystemrelease' => ['11'],
            },
          ],
        )
      end
    end
  end

  describe '.prepare_metadata' do
    include_context 'blank answer file'

    subject(:metadata) { described_class.prepare_metadata(options) }

    before(:each) do
      allow(described_class).to receive(:username_from_login).and_return('testlogin')
    end

    let(:options) { { module_name: 'baz' } }

    context 'when provided :skip-interview => true' do
      let(:options) { { :module_name => 'baz', :'skip-interview' => true } }

      it 'does not perform the module interview' do
        expect(described_class).not_to receive(:module_interview)

        metadata
      end
    end

    context 'when there are no saved answers' do
      before(:each) do
        allow(described_class).to receive(:module_interview).with(any_args)
      end

      it 'guesses the forge username from the system login' do
        expect(metadata.data).to include('name' => 'testlogin-baz')
      end

      it 'sets the version number to a 0.x release' do
        expect(metadata.data).to include('version' => a_string_starting_with('0.'))
      end

      it 'has no dependencies' do
        expect(metadata.data).to include(
          'dependencies' => [],
        )
      end
    end

    context 'when an answer file exists with answers' do
      before(:each) do
        allow(described_class).to receive(:module_interview).with(any_args)

        PDK.answers.update!(
          'forge_username' => 'testuser123',
          'license'        => 'MIT',
          'author'         => 'Test User',
        )
      end

      it 'uses the saved forge_username answer' do
        expect(metadata.data).to include('name' => 'testuser123-baz')
      end

      it 'uses the saved author answer' do
        expect(metadata.data).to include('author' => 'Test User')
      end

      it 'uses the saved license answer' do
        expect(metadata.data).to include('license' => 'MIT')
      end

      context 'and the user specifies a license as a command line option' do
        let(:options) { { module_name: 'baz', license: 'Apache-2.0' } }

        it 'prefers the license specified on the command line over the saved license answer' do
          expect(metadata.data).to include('license' => 'Apache-2.0')
        end
      end
    end
  end

  describe '.prepare_module_directory' do
    let(:path) { 'test123' }

    it 'creates a skeleton directory structure' do
      expect(FileUtils).to receive(:mkdir_p).with(File.join(path, 'examples'))
      expect(FileUtils).to receive(:mkdir_p).with(File.join(path, 'files'))
      expect(FileUtils).to receive(:mkdir_p).with(File.join(path, 'manifests'))
      expect(FileUtils).to receive(:mkdir_p).with(File.join(path, 'templates'))
      expect(FileUtils).to receive(:mkdir_p).with(File.join(path, 'tasks'))

      described_class.prepare_module_directory(path)
    end

    context 'when it fails to create a directory' do
      before(:each) do
        allow(FileUtils).to receive(:mkdir_p).with(anything).and_raise(SystemCallError, 'some message')
      end

      it 'raises a FatalError' do
        expect {
          described_class.prepare_module_directory(path)
        }.to raise_error(PDK::CLI::FatalError, %r{unable to create directory.+some message}i)
      end
    end
  end

  describe '.username_from_login' do
    subject { described_class.username_from_login }

    before(:each) do
      allow(Etc).to receive(:getlogin).and_return(login)
    end

    context 'when the login is entirely alphanumeric' do
      let(:login) { 'testuser123' }

      it 'returns the unaltered login' do
        is_expected.to eq(login)
      end
    end

    context 'when Etc.getlogin returns nil' do
      let(:login) { nil }

      it 'warns the user and returns the string "username"' do
        is_expected.to eq('username')
      end
    end

    context 'when the login contains some non-alphanumeric characters' do
      let(:login) { 'test_user' }

      it 'warns the user and returns the login with the characters removed' do
        expect(logger).to receive(:debug).with(a_string_matching(%r{not a valid forge username}i))
        is_expected.to eq('testuser')
      end
    end

    context 'when the login contains some upper case characters' do
      let(:login) { 'Administrator' }

      it 'warns the user and returns the login with the characters downcased' do
        expect(logger).to receive(:debug).with(a_string_matching(%r{not a valid forge username}i))
        is_expected.to eq('administrator')
      end
    end

    context 'when the login contains only non-alphanumeric characters' do
      let(:login) { 'Αρίσταρχος ό Σάμιος' }

      it 'warns the user and returns the string "username"' do
        expect(logger).to receive(:debug).with(a_string_matching(%r{not a valid forge username}i))
        is_expected.to eq('username')
      end
    end
  end
end
