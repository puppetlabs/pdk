require 'spec_helper_acceptance'

describe 'Specifying a template-ref' do
  after(:all) do
    # We may or may not be in the foo module directory.  If we are, go back one directory.
    # This can happen if you only run a subset of tests in this file.
    Dir.chdir('..') if Dir.pwd.end_with?('foo')
    FileUtils.rm_rf('foo')
    FileUtils.rm('foo_answers.json')
  end

  context 'when creating a new module' do
    create_cmd = [
      'pdk', 'new', 'module', 'foo',
      '--skip-interview',
      '--template-url', 'https://github.com/puppetlabs/pdk-templates',
      '--template-ref', '2.7.1'
    ]

    around do |example|
      old_answer_file = ENV.fetch('PDK_ANSWER_FILE', nil)
      ENV['PDK_ANSWER_FILE'] = 'foo_answers.json'
      example.run
      ENV['PDK_ANSWER_FILE'] = old_answer_file
    end

    describe command(create_cmd.join(' ')) do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(/creating new module: foo/i) }
      its(:stderr) { is_expected.not_to match(/WARN|ERR/) }
      its(:stdout) { is_expected.to match(/\A\Z/) }

      describe file('foo/metadata.json') do
        it { is_expected.to be_file }

        its(:content_as_json) do
          is_expected.to include('template-ref' => match(/2\.7\.1/))
        end
      end
    end

    context 'and then updating the module to a specific ref' do
      before(:all) { Dir.chdir('foo') }

      describe command('pdk update --template-ref 2.7.4 --force') do
        its(:exit_status) { is_expected.to eq(0) }

        describe file('metadata.json') do
          its(:content_as_json) do
            is_expected.to include('template-ref' => match(/2\.7\.4/))
          end
        end
      end
    end
  end
end
