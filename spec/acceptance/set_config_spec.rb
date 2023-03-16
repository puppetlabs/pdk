require 'spec_helper_acceptance'
require 'tempfile'

describe 'pdk set config' do
  include_context 'with a fake TTY'

  shared_examples 'a saved configuration file' do |new_content|
    it 'saves the setting' do
      # Force the command to run if not already
      subject.exit_status
      expect(File).to exist(ENV['PDK_ANSWER_FILE'])

      actual_content = File.open(ENV['PDK_ANSWER_FILE'], 'rb:utf-8') { |f| f.read }
      expect(actual_content).to eq(new_content)
    end
  end

  shared_examples 'a saved JSON configuration file' do |new_json_content|
    it 'saves the setting' do
      # Force the command to run if not already
      subject.exit_status
      expect(File).to exist(ENV['PDK_ANSWER_FILE'])

      actual_content_raw = File.open(ENV['PDK_ANSWER_FILE'], 'rb:utf-8') { |f| f.read }
      actual_json_content = ::JSON.parse(actual_content_raw)
      expect(actual_json_content).to eq(new_json_content)
    end
  end

  RSpec.shared_context 'with a fake answer file' do |initial_content = nil|
    before(:all) do
      fake_answer_file = Tempfile.new('mock_answers.json')
      unless initial_content.nil?
        require 'json'
        fake_answer_file.binmode
        fake_answer_file.write(::JSON.pretty_generate(initial_content))
      end
      fake_answer_file.close
      ENV['PDK_ANSWER_FILE'] = fake_answer_file.path
    end

    after(:all) do
      File.delete(ENV['PDK_ANSWER_FILE']) if File.exist?(ENV['PDK_ANSWER_FILE']) # rubocop:disable PDK/FileDelete,PDK/FileExistPredicate Need actual file calls here
      ENV.delete('PDK_ANSWER_FILE')
    end
  end

  context 'when run outside of a module' do
    describe command('pdk set config') do
      its(:exit_status) { is_expected.not_to eq 0 }
      its(:stdout) { is_expected.to have_no_output }
      its(:stderr) { is_expected.to match(%r{Configuration name is required}) }
    end

    context 'with a setting that does not exist' do
      describe command('pdk set config user.module_defaults.mock value') do
        include_context 'with a fake answer file'

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{user.module_defaults.mock=value}) }
        its(:stderr) { is_expected.to match(%r{Set initial value of 'user.module_defaults.mock' to 'value'}) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 'value'

        # We test the literal output here to make sure it outputs pretty JSON instead of minified JSON
        it_behaves_like 'a saved configuration file', "{\n  \"mock\": \"value\"\n}\n"
      end
    end

    context 'with an existing array setting, not forced' do
      describe command('pdk set config user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => []

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{user.module_defaults.mock=\["value"\]}) }
        its(:stderr) { is_expected.to match(%r{Added new value 'value' to 'user.module_defaults.mock'}) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => ['value']
      end
    end

    context 'with an existing non-array setting, not forced' do
      describe command('pdk set config user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => 1

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{user.module_defaults.mock=value}) }
        its(:stderr) { is_expected.to match(%r{Changed existing value of 'user.module_defaults.mock' from '1' to 'value'}) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 'value'
      end
    end

    context 'with an existing setting, forced' do
      describe command('pdk set config --force user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => []

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{user.module_defaults.mock=value}) }
        its(:stderr) { is_expected.to match(%r{Set initial value of 'user.module_defaults.mock' to 'value'}) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 'value'
      end
    end

    context 'with an existing setting, forced and an explicit type' do
      describe command('pdk set config --force --type number user.module_defaults.mock 1') do
        include_context 'with a fake answer file', 'mock' => []

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{user.module_defaults.mock=1}) }
        its(:stderr) { is_expected.to match(%r{Set initial value of 'user.module_defaults.mock' to '1'}) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 1
      end
    end

    context 'with an existing setting, forced and an explicit type (--as)' do
      describe command('pdk set config --force --as number user.module_defaults.mock 1') do
        include_context 'with a fake answer file', 'mock' => []

        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{user.module_defaults.mock=1}) }
        its(:stderr) { is_expected.to match(%r{Set initial value of 'user.module_defaults.mock' to '1'}) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 1
      end
    end

    context 'with an invalid type' do
      describe command('pdk set config --type invalid_type_name user.module_defaults.mock value') do
        include_context 'with a fake answer file', 'mock' => 'old_value'

        its(:exit_status) { is_expected.not_to eq 0 }
        its(:stdout) { is_expected.to have_no_output }
        its(:stderr) { is_expected.to match(%r{Unknown type invalid_type_name}) }

        it_behaves_like 'a saved JSON configuration file', 'mock' => 'old_value'
      end
    end
  end
end
