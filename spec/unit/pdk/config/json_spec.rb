require 'spec_helper'
require 'tempfile'

describe PDK::Config::JSON do
  subject(:json_config) { described_class.new(file: tempfile) }

  let(:tempfile) do
    file = Tempfile.new('test')
    file.path
  end

  it_behaves_like 'a file based namespace', "{\n  \"foo\": \"bar\"\n}", 'foo' => 'bar'

  describe '#serialize_data' do
    subject(:serialized_data) { json_config.serialize_data(json_config.to_h) }

    context 'when there is no data stored' do
      it 'writes an empty JSON object to disk' do
        expect(serialized_data).to eq("{\n}")
      end
    end

    context 'when there is data stored' do
      it 'writes the JSON object to disk' do
        json_config['foo'] = 'bar'
        expect(serialized_data).to eq("{\n  \"foo\": \"bar\"\n}")
      end
    end
  end
end
