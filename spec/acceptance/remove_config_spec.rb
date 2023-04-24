require 'spec_helper_acceptance'
require 'tempfile'

describe 'pdk remove config' do
  include_context 'with a fake TTY'

  shared_examples 'a saved configuration file' do |new_content|
    it 'saves the setting' do
      # Force the command to run if not already
      subject.exit_status
      expect(File).to exist(ENV.fetch('PDK_ANSWER_FILE', nil))

      actual_content = File.open(ENV.fetch('PDK_ANSWER_FILE', nil), 'rb:utf-8', &:read)
      expect(actual_content).to eq(new_content)
    end
  end

  shared_examples 'a saved JSON configuration file' do |new_json_content|
    it 'saves the setting' do
      # Force the command to run if not already
      subject.exit_status
      expect(File).to exist(ENV.fetch('PDK_ANSWER_FILE', nil))

      actual_content_raw = File.open(ENV.fetch('PDK_ANSWER_FILE', nil), 'rb:utf-8', &:read)
      actual_json_content = JSON.parse(actual_content_raw)
      expect(actual_json_content).to eq(new_json_content)
    end
  end

  RSpec.shared_context 'with a fake answer file' do |initial_content = nil|
    before(:all) do
      fake_answer_file = Tempfile.new('mock_answers.json')
      unless initial_content.nil?
        require 'json'
        fake_answer_file.binmode
        fake_answer_file.write(JSON.pretty_generate(initial_content))
      end
      fake_answer_file.close
      ENV['PDK_ANSWER_FILE'] = fake_answer_file.path
    end

    after(:all) do
      FileUtils.rm_f(ENV.fetch('PDK_ANSWER_FILE', nil)) # Need actual file calls here
      ENV.delete('PDK_ANSWER_FILE')
    end
  end

  context 'when run outside of a module' do
    describe command('pdk remove config') do
      its(:exit_status) { is_expected.not_to eq 0 }
      its(:stdout) { is_expected.to have_no_output }
      its(:stderr) { is_expected.to match(/Configuration name is required/) }
    end

    context 'with a setting that does not exist' do
      describe command('pdk remove config user.module_defaults.mock value') do
        include_context 'with a fake answer file'

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to have_no_output }
        its(:stderr) { is_expected.to match(/Could not remove 'user\.module_defaults\.mock' as it has not been set/) }
      end
    end

    context 'with an existing array setting, not forced' do
      describe command('pdk remove config user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => ['value', 'keep-value']

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=\["keep-value"\]/) }
        its(:stderr) { is_expected.to match(/Removed 'value' from 'user\.module_defaults\.mock'/) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => ['keep-value']
      end
    end

    context 'with an existing array setting, forced' do
      describe command('pdk remove config user.module_defaults.mock --force') do
        include_context 'with a fake answer file', 'mock' => ['value', 'keep-value']

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=$/) }
        its(:stderr) { is_expected.to match(/Removed 'user\.module_defaults\.mock' which had a value of '\["value", "keep-value"\]/) }

        it_behaves_like 'a saved JSON configuration file', {}
      end
    end

    context 'with an existing non-array setting, not forced' do
      describe command('pdk remove config user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => 1

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=$/) }
        its(:stderr) { is_expected.to match(/Removed 'user\.module_defaults\.mock' which had a value of '1'/) }

        it_behaves_like 'a saved JSON configuration file', {}
      end
    end

    context 'with an existing setting, forced' do
      describe command('pdk remove config --force user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => 'value'

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/user.module_defaults.mock=$/) }
        its(:stderr) { is_expected.to match(/Ignoring --force as the setting is not multi-valued/) }
        its(:stderr) { is_expected.to match(/Removed 'user\.module_defaults\.mock' which had a value of 'value'/) }

        it_behaves_like 'a saved JSON configuration file', {}
      end
    end
  end
end
