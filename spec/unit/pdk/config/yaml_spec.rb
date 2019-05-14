require 'spec_helper'

describe PDK::Config::YAML do
  subject(:yaml_config) { described_class.new(file: tempfile) }

  let(:tempfile) do
    file = Tempfile.new('test')
    file.write(data)
    file.close
    file.path
  end
  let(:data) { nil }

  describe '#parse_data' do
    subject(:parse_data) { yaml_config.parse_data(data, tempfile) }

    context 'when the file does not exist or is unreadable' do
      let(:data) { nil }

      it 'returns an empty hash' do
        expect(parse_data).to eq({})
      end
    end

    context 'when the file contains a valid YAML object' do
      let(:data) { "---\nfoo: bar\n" }

      it 'returns the parsed YAML as a Hash' do
        expect(parse_data).to eq('foo' => 'bar')
      end
    end

    context 'when the file contains invalid YAML' do
      let(:data) { "---\n\tfoo: bar" }

      it 'raises PDK::Config::LoadError' do
        expect { parse_data }.to raise_error(PDK::Config::LoadError, %r{syntax error}i)
      end
    end

    context 'when the file contains valid YAML with invalid data classes' do
      let(:data) { "--- !ruby/object:File {}\n" }

      it 'raises PDK::Config::LoadError' do
        expect { parse_data }.to raise_error(PDK::Config::LoadError, %r{unsupported class}i)
      end
    end
  end

  describe '#serialize_data' do
    subject(:serialized_data) { yaml_config.serialize_data(yaml_config.to_h) }

    context 'when there is no data stored' do
      it 'writes an empty YAML hash to disk' do
        expect(serialized_data).to eq("--- {}\n")
      end
    end

    context 'when there is data stored' do
      it 'writes the YAML document to disk' do
        yaml_config['foo'] = 'bar'
        expect(serialized_data).to eq("---\nfoo: bar\n")
      end
    end
  end
end
