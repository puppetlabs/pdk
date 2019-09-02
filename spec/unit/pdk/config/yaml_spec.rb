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

 it_behaves_like 'a file based namespace', "---\nfoo: bar\n", 'foo' => 'bar'

  describe '#parse_file' do
    subject(:parse_file) { yaml_config.parse_file(tempfile) {} }

    context 'when the file contains invalid YAML' do
      let(:data) { "---\n\tfoo: bar" }

      it 'raises PDK::Config::LoadError' do
        expect { parse_file }.to raise_error(PDK::Config::LoadError, %r{syntax error}i)
      end
    end

    context 'when the file contains valid YAML with invalid data classes' do
      let(:data) { "--- !ruby/object:File {}\n" }

      it 'raises PDK::Config::LoadError' do
        expect { parse_file }.to raise_error(PDK::Config::LoadError, %r{unsupported class}i)
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
