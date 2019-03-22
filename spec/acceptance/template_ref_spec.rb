require 'spec_helper_acceptance'

describe 'Specifying a template-ref' do
  after(:all) do
    Dir.chdir('..')
    FileUtils.rm_rf('foo')
    FileUtils.rm('foo_answers.json')
  end

  context 'when creating a new module' do
    create_cmd = [
      'pdk', 'new', 'module', 'foo',
      '--skip-interview',
      '--template-url', 'https://github.com/puppetlabs/pdk-templates',
      '--template-ref', '1.7.0',
      '--answer-file', 'foo_answers.json'
    ]

    describe command(create_cmd.join(' ')) do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{creating new module: foo}i) }
      its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }

      describe file('foo/metadata.json') do
        it { is_expected.to be_file }
        its(:content_as_json) do
          is_expected.to include('template-ref' => match(%r{1\.7\.0}))
        end
      end
    end

    context 'and then updating the module to a specific ref' do
      before(:all) { Dir.chdir('foo') }

      describe command('pdk update --template-ref 1.8.0 --force') do
        its(:exit_status) { is_expected.to eq(0) }

        describe file('metadata.json') do
          its(:content_as_json) do
            is_expected.to include('template-ref' => match(%r{1\.8\.0}))
          end
        end
      end
    end
  end
end
