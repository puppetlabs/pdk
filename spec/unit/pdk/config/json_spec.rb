require 'spec_helper'
require 'tempfile'

describe PDK::Config::JSON do
  subject(:json_config) { described_class.new(file: tempfile) }

  let(:tempfile) do
    file = Tempfile.new('test')
    file.write(data)
    file.close
    file.path
  end
  let(:data) { '{}' }

  describe '#parse_data' do
    subject(:parse_data) { json_config.parse_data(data, tempfile) }

    context 'when the file does not exist or is unreadable' do
      let(:data) { nil }

      it 'returns an empty hash' do
        expect(parse_data).to eq({})
      end
    end

    context 'when the file contains a valid JSON object' do
      let(:data) { '{ "foo": "bar" }' }

      it 'returns the parsed JSON as a Hash' do
        expect(parse_data).to eq('foo' => 'bar')
      end
    end
  end

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
