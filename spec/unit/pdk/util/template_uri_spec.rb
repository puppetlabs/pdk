require 'spec_helper'
require 'pdk/util/template_uri'
require 'addressable'

describe PDK::Util::TemplateURI do
  subject(:template_uri) do
    described_class.new(opts_or_uri)
  end

  include_context 'mock configuration'

  before(:each) do
    PDK.config.set(%w[user module_defaults template-url], nil)
    allow(PDK::Util).to receive(:module_root).and_return(nil)
    allow(PDK::Util).to receive(:package_install?).and_return(false)
  end

  describe '.new' do
    context 'with a string' do
      context 'that contains a valid URI' do
        let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git#custom' }

        it 'can return a string for storing' do
          expect(template_uri.to_s).to eq('https://github.com/my/pdk-templates.git#custom')
        end
      end

      context 'that contains the default template keyword' do
        let(:opts_or_uri) { 'pdk-default#1.2.3' }

        before(:each) do
          allow(PDK::Util).to receive(:package_install?).and_return(false)
        end

        it 'converts the keyword to the default template URI' do
          expect(template_uri.to_s).to eq('https://github.com/puppetlabs/pdk-templates#1.2.3')
        end
      end

      context 'that contains an invalid URI' do
        let(:opts_or_uri) { 'https://' }

        it 'raises a FatalError' do
          expect {
            template_uri
          }.to raise_error(PDK::CLI::FatalError, %r{initialization with a non-uri string}i)
        end
      end
    end

    context 'with an Addressable::URI' do
      let(:opts_or_uri) { Addressable::URI.parse('https://github.com/my/pdk-templates.git#custom') }

      it 'can return a string for storing' do
        expect(template_uri.to_s).to eq('https://github.com/my/pdk-templates.git#custom')
      end
    end

    context 'with a PDK::Util::TemplateURI' do
      let(:opts_or_uri) { described_class.new('https://example.com/my/template') }

      it 'can return a string for storing' do
        expect(template_uri.to_s).to eq(opts_or_uri.to_s)
      end
    end

    context 'with options' do
      let(:opts_or_uri) do
        {
          'template-url': 'https://github.com/my/pdk-templates.git',
          'template-ref': 'custom',
        }
      end

      it 'can return a string for storing' do
        allow(PDK::Util::Git).to receive(:repo?).with(anything).and_return(true)
        expect(template_uri.to_s).to eq('https://github.com/my/pdk-templates.git#custom')
      end
    end

    context 'combinations of answers, options, and defaults' do
      let(:module_root) { '/path/to/module' }
      let(:pdk_version) { '1.2.3' }
      let(:template_url) { 'metadata-templates' }
      let(:template_ref) { nil }
      let(:mock_metadata) do
        instance_double(
          PDK::Module::Metadata,
          data: {
            'pdk-version' => pdk_version,
            'template-url' => template_url,
            'template-ref' => template_ref,
          },
        )
      end

      let(:opts_or_uri) { {} }
      let(:default_uri) { "#{described_class.default_template_uri}##{described_class.default_template_ref}" }

      before :each do
        allow(PDK::Util::Git).to receive(:repo?).with(anything).and_return(true)
        allow(PDK::Util).to receive(:module_root).and_return(module_root)
        allow(PDK::Util).to receive(:development_mode?).and_return(false)
      end

      context 'when passed no options' do
        context 'and there are no metadata or answers' do
          before(:each) do
            allow(PDK::Util::Filesystem).to receive(:file?).with(File.join(module_root, 'metadata.json')).and_return(false)
          end

          it 'returns the default template' do
            expect(template_uri.to_s).to eq(default_uri)
          end
        end

        context 'and there are only answers' do
          before :each do
            PDK.config.set(%w[user module_defaults template-url], 'answer-templates')
            allow(PDK::Util::Filesystem).to receive(:file?).with(File.join(module_root, 'metadata.json')).and_return(false)
          end

          it 'returns the answers template' do
            expect(template_uri.to_s).to eq('answer-templates')
          end

          context 'and the answer file template is invalid' do
            before(:each) do
              allow(described_class).to receive(:valid_template?).with(anything).and_call_original
              allow(described_class).to receive(:valid_template?).with(uri: anything, type: anything, allow_fallback: true).and_return(false)
            end

            it 'returns the default template' do
              expect(template_uri.to_s).to eq(default_uri)
            end
          end
        end

        context 'and there are metadata and answers' do
          before :each do
            PDK.config.set(%w[user module_defaults template-url], 'answer-templates')
          end

          it 'returns the metadata template' do
            allow(PDK::Module::Metadata).to receive(:from_file).with('/path/to/module/metadata.json').and_return(mock_metadata)
            allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/module/metadata.json').and_return(true)
            allow(PDK::Util::Filesystem).to receive(:file?).with(%r{PDK_VERSION}).and_return(true)
            expect(template_uri.to_s).to eq('metadata-templates')
          end
        end
      end

      context 'when there are metadata and answers' do
        before :each do
          PDK.config.set(%w[user module_defaults template-url], 'answer-templates')
          allow(PDK::Util::Filesystem).to receive(:file?).with(File.join(PDK::Util.module_root, 'metadata.json')).and_return(true)
          allow(PDK::Module::Metadata).to receive(:from_file).with(File.join(PDK::Util.module_root, 'metadata.json')).and_return(mock_metadata)
        end

        context 'and passed template-url' do
          let(:opts_or_uri) { { 'template-url': 'cli-templates' } }

          it 'returns the specified template' do
            expect(template_uri.to_s).to eq('cli-templates#main')
          end
        end

        context 'and passed windows template-url' do
          let(:opts_or_uri) { { 'template-url': 'C:\\cli-templates' } }

          it 'returns the specified template' do
            allow(Gem).to receive(:win_platform?).and_return(true)
            expect(template_uri.to_s).to eq('C:\\cli-templates#main')
          end
        end

        context 'and passed template-url and template-ref' do
          let(:opts_or_uri) { { 'template-url': 'cli-templates', 'template-ref': 'cli-ref' } }

          it 'returns the specified template and ref' do
            uri = Addressable::URI.parse('cli-templates')
            uri.fragment = 'cli-ref'
            expect(template_uri.to_s).to eq(uri.to_s)
          end
        end
      end
    end
  end

  describe '.bare_uri' do
    context 'when the uri has a fragment' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git#custom' }

      it 'returns just the url portion' do
        expect(template_uri.bare_uri).to eq 'https://github.com/my/pdk-templates.git'
      end
    end

    context 'when the uri has no fragment' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git' }

      it 'returns just the url portion' do
        expect(template_uri.bare_uri).to eq 'https://github.com/my/pdk-templates.git'
      end
    end

    context 'when the uri is an absolute path' do
      context 'on linux' do
        let(:opts_or_uri) { '/my/pdk-templates.git#custom' }

        it 'returns url portion' do
          allow(Gem).to receive(:win_platform?).and_return(false)
          expect(template_uri.bare_uri).to eq '/my/pdk-templates.git'
        end
      end

      context 'on windows' do
        let(:opts_or_uri) { '/C:/my/pdk-templates.git#custom' }

        it 'returns url portion' do
          allow(Gem).to receive(:win_platform?).and_return(true)
          expect(template_uri.bare_uri).to eq 'C:/my/pdk-templates.git'
        end
      end
    end
  end

  describe '.uri_fragment' do
    context 'when the uri has a fragment' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git#custom' }

      it 'returns just the fragment portion' do
        expect(template_uri.uri_fragment).to eq 'custom'
      end
    end

    context 'when the uri has no fragment' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git' }

      it 'returns the default ref' do
        expect(template_uri.uri_fragment).to eq(described_class.default_template_ref(opts_or_uri))
      end
    end
  end

  describe '.shell_path' do
    context 'when the uri has a schema' do
      context 'on linux' do
        let(:opts_or_uri) { 'file:///my/pdk-templates.git#fragment' }

        it 'returns the path' do
          allow(Gem).to receive(:win_platform?).and_return(false)
          expect(template_uri.shell_path).to eq '/my/pdk-templates.git'
        end
      end

      context 'on windows' do
        let(:opts_or_uri) { 'file:///C:/my/pdk-templates.git#fragment' }

        it 'returns the path' do
          allow(Gem).to receive(:win_platform?).and_return(true)
          expect(template_uri.shell_path).to eq 'C:/my/pdk-templates.git'
        end
      end
    end

    context 'when the uri is just an absolute path' do
      context 'on linux' do
        let(:opts_or_uri) { '/my/pdk-templates.git#custom' }

        it 'returns url portion' do
          allow(Gem).to receive(:win_platform?).and_return(false)
          expect(template_uri.shell_path).to eq '/my/pdk-templates.git'
        end
      end

      context 'on windows' do
        let(:opts_or_uri) { '/C:/my/pdk-templates.git#custom' }

        it 'returns url portion' do
          allow(Gem).to receive(:win_platform?).and_return(true)
          expect(template_uri.shell_path).to eq 'C:/my/pdk-templates.git'
        end
      end
    end
  end

  describe '.default_template_uri' do
    subject(:default_uri) { described_class.default_template_uri }

    context 'when it is a package install' do
      before(:each) do
        allow(PDK::Util).to receive(:package_install?).and_return(true)
      end

      it 'returns the file template repo' do
        allow(PDK::Util).to receive(:package_cachedir).and_return('/path/to/pdk')
        expect(default_uri.to_s).to eq('file:///path/to/pdk/pdk-templates.git')
      end
    end

    context 'when it is not a package install' do
      before(:each) do
        allow(PDK::Util).to receive(:package_install?).and_return(false)
      end

      it 'returns puppetlabs template url' do
        expect(default_uri.to_s).to eq('https://github.com/puppetlabs/pdk-templates')
      end
    end
  end

  describe '.default_template_ref' do
    subject { described_class.default_template_ref(uri) }

    before(:each) do
      allow(PDK::Util).to receive(:development_mode?).and_return(development_mode)
    end

    context 'with a custom template repo' do
      let(:uri) { described_class.new('https://github.com/my/template') }

      context 'in development mode' do
        let(:development_mode) { true }

        it 'returns main' do
          expect(subject).to eq('main')
        end
      end

      context 'not in development mode' do
        let(:development_mode) { false }

        it 'returns main' do
          expect(subject).to eq('main')
        end
      end
    end

    context 'with the default template repo' do
      let(:uri) { described_class.default_template_uri }

      context 'not in development mode' do
        let(:development_mode) { false }

        it 'returns the built-in TEMPLATE_REF' do
          expect(subject).to eq(PDK::TEMPLATE_REF)
        end
      end

      context 'in development mode' do
        let(:development_mode) { true }

        it 'returns main' do
          expect(subject).to eq('main')
        end
      end
    end

    context 'with an explicit nil template' do
      let(:uri) { nil }

      context 'not in development mode' do
        let(:development_mode) { false }

        it 'returns the built-in TEMPLATE_REF' do
          expect(subject).to eq(PDK::TEMPLATE_REF)
        end
      end

      context 'in development mode' do
        let(:development_mode) { true }

        it 'returns main' do
          expect(subject).to eq('main')
        end
      end
    end
  end

  describe '.templates' do
    subject { described_class.templates(options) }

    let(:options) { {} }

    context 'when provided a template-url' do
      subject(:cli_template_uri) { described_class.templates('template-url': template_url).first[:uri] }

      context 'that is a ssh:// URL without a port' do
        let(:template_url) { 'ssh://git@github.com/1234/repo.git' }

        it 'parses into an Addressable::URI without port set' do
          expect(cli_template_uri).to have_attributes(
            scheme: 'ssh',
            user: 'git',
            host: 'github.com',
            port: nil,
            path: '/1234/repo.git',
          )
        end
      end

      context 'that is a ssh:// URL with a port' do
        let(:template_url) { 'ssh://git@github.com:1234/user/repo.git' }

        it 'parses into an Addressable::URI with port set' do
          expect(cli_template_uri).to have_attributes(
            scheme: 'ssh',
            user: 'git',
            host: 'github.com',
            port: 1234,
            path: '/user/repo.git',
          )
        end
      end

      context 'that is a SCP style URL with a non-numeric relative path' do
        let(:template_url) { 'git@github.com:user/repo.git' }

        it 'parses into an Addressable::URI without port set' do
          expect(cli_template_uri).to have_attributes(
            scheme: 'ssh',
            user: 'git',
            host: 'github.com',
            port: nil,
            path: '/user/repo.git',
          )
        end
      end

      context 'that is a SCP style URL with a numeric relative path' do
        let(:template_url) { 'git@github.com:1234/repo.git' }

        it 'parses the numeric part as part of the path' do
          expect(cli_template_uri).to have_attributes(
            scheme: 'ssh',
            user: 'git',
            host: 'github.com',
            port: nil,
            path: '/1234/repo.git',
          )
        end
      end
    end

    context 'when the answers file has saved template-url value' do
      before(:each) do
        PDK.config.set(%w[user module_defaults template-url], answers_template_url)
      end

      context 'that is the deprecated pdk-module-template' do
        let(:answers_template_url) { 'https://github.com/puppetlabs/pdk-module-template' }

        it 'converts it to the new default template URL' do
          expect(subject).to include(
            type: 'PDK answers',
            uri: Addressable::URI.parse('https://github.com/puppetlabs/pdk-templates'),
            allow_fallback: true,
          )
        end
      end

      context 'that contains any other URL' do
        let(:answers_template_url) { 'https://github.com/my/pdk-template' }

        it 'uses the template as specified' do
          expect(subject).to include(
            type: 'PDK answers',
            uri: Addressable::URI.parse(answers_template_url),
            allow_fallback: true,
          )
        end
      end
    end

    context 'when the answers file has no saved template-url value' do
      before(:each) do
        PDK.config.set(%w[user module_defaults template-url], nil)
      end

      it 'does not include a PDK answers template option' do
        expect(subject).not_to include(type: 'PDK answers', uri: anything, allow_fallback: true)
      end
    end

    context 'when the metadata contains a template-url' do
      let(:mock_metadata) do
        instance_double(
          PDK::Module::Metadata,
          data: {
            'pdk-version' => PDK::VERSION,
            'template-url' => metadata_url,
          },
        )
      end

      before(:each) do
        allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
        allow(PDK::Util).to receive(:development_mode?).and_return(false)
        allow(PDK::Module::Metadata).to receive(:from_file).with('/path/to/module/metadata.json').and_return(mock_metadata)
        allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/module/metadata.json').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:file?).with(%r{PDK_VERSION}).and_return(true)
      end

      context 'that is a pdk-default keyword' do
        let(:metadata_url) { 'pdk-default#main' }
        let(:expected_uri) { described_class.default_template_addressable_uri.tap { |obj| obj.fragment = 'main' } }

        it 'converts the keyword to the default template' do
          expect(subject).to include(
            type: 'metadata.json',
            uri: expected_uri,
            allow_fallback: true,
          )
        end
      end

      context 'that is an SCP style URL' do
        let(:metadata_url) { 'git@github.com:puppetlabs/pdk-templates.git' }

        it 'converts the URL to and ssh:// URI' do
          expect(subject).to include(
            type: 'metadata.json',
            uri: Addressable::URI.new(
              scheme: 'ssh',
              user: 'git',
              host: 'github.com',
              path: '/puppetlabs/pdk-templates.git',
            ),
            allow_fallback: true,
          )
        end
      end
    end
  end

  describe '.valid_template?' do
    subject(:return_val) { described_class.valid_template?(template) }

    context 'when passed nil' do
      let(:template) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when passed a param that is not a Hash' do
      let(:template) { 'https://github.com/my/template' }

      it { is_expected.to be_falsey }
    end

    context 'when passed a param that is a Hash' do
      let(:template) { { allow_fallback: true } }

      context 'with a nil :uri' do
        let(:template) { super().merge(uri: nil) }

        it { is_expected.to be_falsey }
      end

      context 'and the :uri value is not an Addressable::URI' do
        let(:template) { super().merge(uri: 'https://github.com/my/template') }

        it { is_expected.to be_falsey }
      end

      context 'and the :uri value is an Addressable::URI' do
        let(:template) { super().merge(uri: Addressable::URI.parse('/path/to/a/template')) }

        context 'that points to a git repository' do
          before(:each) do
            allow(PDK::Util::Git).to receive(:repo?).with('/path/to/a/template').and_return(true)
          end

          it { is_expected.to be_truthy }
        end

        context 'that does not point to a git repository' do
          before(:each) do
            allow(PDK::Util::Git).to receive(:repo?).with('/path/to/a/template').and_return(false)
          end

          def allow_template_dir(root, valid)
            # Note this are Template V1 directories. V2, and so on, may have different requirements
            allow(PDK::Util::Filesystem).to receive(:directory?).with("#{root}/moduleroot").and_return(valid)
            allow(PDK::Util::Filesystem).to receive(:directory?).with("#{root}/moduleroot_init").and_return(valid)
          end

          context 'but does point to a directory' do
            before(:each) do
              allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/a/template').and_return(true)
            end

            context 'that contains a valid template' do
              before(:each) do
                allow_template_dir('/path/to/a/template', true)
              end

              it { is_expected.to be_truthy }
            end

            context 'that does not contain a valid template' do
              before(:each) do
                allow_template_dir('/path/to/a/template', false)
              end

              it { is_expected.to be_falsey }
            end
          end

          context 'and the param Hash sets :allow_fallback => false' do
            let(:template) { super().merge(allow_fallback: false) }

            it 'raises a FatalError' do
              expect { return_val }.to raise_error(PDK::CLI::FatalError, %r{unable to find a valid template}i)
            end
          end
        end
      end
    end
  end

  describe '.packaged_template?' do
    subject { described_class.packaged_template?(path) }

    context 'when the path is windows default' do
      let(:path) { 'file:///C:/Program Files/Puppet Labs/DevelopmentKit/share/cache/pdk-templates.git' }

      it { is_expected.to be_truthy }
    end

    context 'when the path is posix default' do
      let(:path) { 'file:///opt/puppetlabs/pdk/share/cache/pdk-templates.git' }

      it { is_expected.to be_truthy }
    end

    context 'when the path is the default template keyword' do
      let(:path) { described_class::PACKAGED_TEMPLATE_KEYWORD }

      it { is_expected.to be_truthy }
    end

    context 'when the path is not a default' do
      let(:path) { File.join('a', 'custom', 'path') }

      it { is_expected.to be_falsey }
    end
  end

  describe '#metadata_format' do
    subject { described_class.new(url).metadata_format }

    context 'when running PDK from a package' do
      before(:each) do
        allow(PDK::Util).to receive(:package_install?).and_return(true)
        allow(PDK::Util).to receive(:pdk_package_basedir).and_return('/opt/puppetlabs/pdk')
      end

      context 'and using the packaged windows template' do
        let(:url) { "#{described_class::LEGACY_PACKAGED_TEMPLATE_PATHS['windows']}#main" }

        it { is_expected.to eq('pdk-default#main') }
      end

      context 'and using the packaged linux template' do
        let(:url) { "#{described_class::LEGACY_PACKAGED_TEMPLATE_PATHS['linux']}#something" }

        it { is_expected.to eq('pdk-default#something') }
      end

      context 'and using the packaged osx template' do
        let(:url) { "#{described_class::LEGACY_PACKAGED_TEMPLATE_PATHS['macos']}#else" }

        it { is_expected.to eq('pdk-default#else') }
      end
    end

    context 'when not running PDK from a package' do
      before(:each) do
        allow(PDK::Util).to receive(:package_install?).and_return(false)
      end

      context 'and using the packaged windows template' do
        let(:url) { "#{described_class::LEGACY_PACKAGED_TEMPLATE_PATHS['windows']}#main" }

        it { is_expected.to eq('https://github.com/puppetlabs/pdk-templates#main') }
      end

      context 'and using the packaged linux template' do
        let(:url) { "#{described_class::LEGACY_PACKAGED_TEMPLATE_PATHS['linux']}#something" }

        it { is_expected.to eq('https://github.com/puppetlabs/pdk-templates#something') }
      end

      context 'and using the packaged osx template' do
        let(:url) { "#{described_class::LEGACY_PACKAGED_TEMPLATE_PATHS['macos']}#else" }

        it { is_expected.to eq('https://github.com/puppetlabs/pdk-templates#else') }
      end
    end
  end
end
