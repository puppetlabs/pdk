require 'spec_helper'

describe PDK::Util::TemplateURI do
  before :all do
    PDK.answers.update!('template-url' => nil)
  end

  subject(:template_uri) do
    described_class.new(opts_or_uri)
  end

  describe '.new' do
    context 'with a string' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git#custom' }

      it 'can return a string for storing' do
        expect(template_uri.to_s).to eq('https://github.com/my/pdk-templates.git#custom')
      end
    end
    context 'with an addressable::uri' do
      let(:opts_or_uri) { Addressable::URI.parse('https://github.com/my/pdk-templates.git#custom') }

      it 'can return a string for storing' do
        expect(template_uri.to_s).to eq('https://github.com/my/pdk-templates.git#custom')
      end
    end
    context 'with options' do
      let(:opts_or_uri) do
        {
          :'template-url' => 'https://github.com/my/pdk-templates.git',
          :'template-ref' => 'custom',
        }
      end

      it 'can return a string for storing' do
        allow(PDK::Util::Git).to receive(:repo?).with(anything).and_return(true)
        expect(template_uri.to_s).to eq('https://github.com/my/pdk-templates.git#custom')
      end
    end
    context 'combinations of answers, options, and defaults' do
      before :each do
        allow(PDK::Util::Git).to receive(:repo?).with(anything).and_return(true)
        allow(PDK::Util).to receive(:module_root).and_return('/path/to/module')
        allow(PDK::Util).to receive(:development_mode?).and_return(false)
      end

      let(:pdk_version) { '1.2.3' }
      let(:template_url) { 'metadata-templates' }
      let(:template_ref) { nil }
      let(:mock_metadata) do
        instance_double(
          PDK::Module::Metadata,
          data: {
            'pdk-version'  => pdk_version,
            'template-url' => template_url,
            'template-ref' => template_ref,
          },
        )
      end

      let(:opts_or_uri) { {} }

      context 'when passed no options' do
        context 'and there are no metadata or answers' do
          before :each do
            PDK.answers.update!('template-url' => nil)
          end
          it 'returns the default template' do
            expect(template_uri.to_s).to eq(described_class.default_template_uri.to_s)
          end
        end
        context 'and there are only answers' do
          before :each do
            PDK.answers.update!('template-url' => 'answer-templates')
          end
          it 'returns the answers template' do
            expect(template_uri.to_s).to eq('answer-templates')
          end

          context 'and the answer file template is invalid' do
            before(:each) do
              allow(template_uri).to receive(:valid_template?).with(anything).and_call_original
              allow(template_uri).to receive(:valid_template?).with(uri: anything, type: anything, allow_fallback: true).and_return(false)
            end

            it 'returns the default template' do
              pending
              expect(template_uri.to_s).to eq(described_class.default_template_uri.to_s)
            end
          end
        end
        context 'and there are metadata and answers' do
          before :each do
            PDK.answers.update!('template-url' => 'answer-templates')
          end
          it 'returns the metadata template' do
            allow(PDK::Module::Metadata).to receive(:from_file).with('/path/to/module/metadata.json').and_return(mock_metadata)
            allow(File).to receive(:file?).with('/path/to/module/metadata.json').and_return(true)
            allow(File).to receive(:file?).with(%r{PDK_VERSION}).and_return(true)
            expect(template_uri.to_s).to eq('metadata-templates')
          end
        end
      end
      context 'when there are metadata and answers' do
        before :each do
          PDK.answers.update!('template-url' => 'answer-templates')
          allow(PDK::Module::Metadata).to receive(:from_file).with(File.join(PDK::Util.module_root, 'metadata.json')).and_return(mock_metadata)
        end

        context 'and passed template-url' do
          let(:opts_or_uri) { { :'template-url' => 'cli-templates' } }

          it 'returns the specified template' do
            expect(template_uri.to_s).to eq('cli-templates')
          end
        end
        context 'and passed windows template-url' do
          let(:opts_or_uri) { { :'template-url' => 'C:\cli-templates' } }

          it 'returns the specified template' do
            allow(Gem).to receive(:win_platform?).and_return(true)
            expect(template_uri.to_s).to eq('C:\cli-templates')
          end
        end
        context 'and passed template-ref' do
          let(:opts_or_uri) { { :'template-ref' => 'cli-ref' } }

          it 'errors because it requires url with ref' do
            expect { template_uri }.to raise_error(PDK::CLI::FatalError, %r{--template-ref requires --template-url})
          end
        end
        context 'and passed template-url and template-ref' do
          let(:opts_or_uri) { { :'template-url' => 'cli-templates', :'template-ref' => 'cli-ref' } }

          it 'returns the specified template and ref' do
            uri = Addressable::URI.parse('cli-templates')
            uri.fragment = 'cli-ref'
            expect(template_uri.to_s).to eq(uri.to_s)
          end
        end
      end
    end
  end

  describe '.git_remote' do
    context 'when the uri has a fragment' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git#custom' }

      it 'returns just the url portion' do
        expect(template_uri.git_remote).to eq 'https://github.com/my/pdk-templates.git'
      end
    end

    context 'when the uri has no fragment' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git' }

      it 'returns just the url portion' do
        expect(template_uri.git_remote).to eq 'https://github.com/my/pdk-templates.git'
      end
    end

    context 'when the uri is an absolute path' do
      context 'on linux' do
        let(:opts_or_uri) { '/my/pdk-templates.git#custom' }

        it 'returns url portion' do
          allow(Gem).to receive(:win_platform?).and_return(false)
          expect(template_uri.git_remote).to eq '/my/pdk-templates.git'
        end
      end
      context 'on windows' do
        let(:opts_or_uri) { '/C:/my/pdk-templates.git#custom' }

        it 'returns url portion' do
          allow(Gem).to receive(:win_platform?).and_return(true)
          expect(template_uri.git_remote).to eq 'C:/my/pdk-templates.git'
        end
      end
    end
  end

  describe '.git_ref' do
    context 'when the uri has a fragment' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git#custom' }

      it 'returns just the ref portion' do
        expect(template_uri.git_ref).to eq 'custom'
      end
    end

    context 'when the uri has no fragment' do
      let(:opts_or_uri) { 'https://github.com/my/pdk-templates.git' }

      it 'returns the default ref' do
        expect(template_uri.git_ref).to eq described_class.default_template_ref
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
    subject { described_class.default_template_uri }

    context 'when it is a package install' do
      before(:each) do
        allow(described_class).to receive(:package_install?).and_return(true)
      end

      it 'returns the file template repo' do
        allow(described_class).to receive(:package_cachedir).and_return('/path/to/pdk')
        is_expected.to eq(Addressable::URI.parse('file:///path/to/pdk/pdk-templates.git'))
      end
    end
    context 'when it is not a package install' do
      before(:each) do
        allow(described_class).to receive(:package_install?).and_return(false)
      end

      it 'returns puppetlabs template url' do
        is_expected.to eq(Addressable::URI.parse('https://github.com/puppetlabs/pdk-templates'))
      end
    end
  end

  describe '.default_template_ref' do
    subject { described_class.default_template_ref }

    context 'with a custom template repo' do
      before(:each) do
        allow(described_class).to receive(:default_template_url).and_return('custom_template_url')
      end

      it 'returns master' do
        is_expected.to eq('master')
      end
    end

    context 'with the default template repo' do
      before(:each) do
        allow(described_class).to receive(:default_template_url).and_return('puppetlabs_template_url')
      end

      context 'not in development mode' do
        before(:each) do
          allow(described_class).to receive(:development_mode?).and_return(false)
        end

        it 'returns the built-in TEMPLATE_REF' do
          is_expected.to eq(PDK::TEMPLATE_REF)
        end
      end

      context 'in development mode' do
        before(:each) do
          allow(described_class).to receive(:development_mode?).and_return(true)
        end

        it 'returns master' do
          is_expected.to eq('master')
        end
      end
    end
  end

end