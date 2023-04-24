require 'spec_helper'
require 'tempfile'
require 'pdk/config/ini_file'
require 'pdk/config/ini_file_setting'

RSpec.shared_examples 'an ini file based namespace reader' do |content, expected_settings|
  before do
    allow(PDK::Util::Filesystem).to receive(:mkdir_p)
  end

  describe '#parse_file' do
    before do
      expect(ini_config).to receive(:load_data).and_return(content)
    end

    it 'returns the parsed data' do
      settings = {}
      ini_config.parse_file(ini_config.file) { |k, v| settings[k] = v }

      expect(settings.keys).to eq(expected_settings.keys)
      expected_settings.each do |expected_key, expected_value|
        expect(settings[expected_key].value).to eq(expected_value)
      end
    end
  end
end

RSpec.shared_examples 'an ini file based namespace writer' do |settings, expected_content|
  describe '#serialize_data' do
    it 'returns the serialized data' do
      expect(ini_config.serialize_data(settings)).to eq(expected_content)
    end
  end
end

describe PDK::Config::IniFile do
  subject(:ini_config) { described_class.new(file: tempfile) }

  let(:tempfile) do
    file = Tempfile.new('test')
    file.path
  end

  it_behaves_like 'a file based namespace', "key = 0\n\n[foo]\nbar = baz\n", 'key' => '0', 'foo' => { 'bar' => 'baz' }

  it_behaves_like 'a file based namespace without a schema'

  context 'when the file contains invalid data' do
    before do
      # Note this isn't the best testing method, however there isn't really a way to craft an ini file to
      # actually raise an error.
      allow_any_instance_of(PDK::Config::IniFileSetting).to receive(:validate!).and_call_original # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(PDK::Config::IniFileSetting).to receive(:validate!).with('error').and_raise('Mock Validation Error') # rubocop:disable RSpec/AnyInstance
    end

    # Invalid values are set to `nil`
    include_examples 'an ini file based namespace reader', "key = error\n\n[foo]\nbar = baz\n", 'key' => nil, 'foo' => { 'bar' => 'baz' }
  end

  context 'when the file contains quoted values and settings' do
    # Quoted keys are ignored, values are not
    include_examples 'an ini file based namespace reader', "\"key\" = \"0\"\nabc = \"123\"\n[foo]\nbar = \"baz\"\n", 'abc' => '123', 'foo' => { 'bar' => 'baz' }
  end

  context 'when the settings contains values with spaces' do
    include_examples 'an ini file based namespace writer',
                     { 's1' => 'v1', 'abc' => '12 3', 'fo o' => { 'ba r' => '  baz  ' } },
                     "s1 = v1\nabc = \"12 3\"\n\n[fo o]\nba r = \"  baz  \"\n"
  end

  context 'when the settings contains values with nil' do
    # nil values are not written
    include_examples 'an ini file based namespace writer',
                     { 's1' => 'v1', 'abc' => nil, 'foo' => { 'bar' => nil } },
                     "s1 = v1\n\n[foo]\n"
    it_behaves_like 'a file based namespace', "s1 = v1\n\n[foo]\n", 's1' => 'v1', 'foo' => {}
  end
end
