# rubocop:disable RSpec/NamedSubject This is a shared example, you don't know what the name of the subject is
RSpec.shared_examples 'a file based namespace' do |content, expected_settings|
  before(:each) do
    allow(PDK::Util::Filesystem).to receive(:mkdir_p)
  end

  describe '#parse_file' do
    context 'when the file contains valid data' do
      before(:each) do
        expect(subject).to receive(:load_data).and_return(content)
      end

      it 'returns the parsed data' do
        settings = {}
        subject.parse_file(subject.file) { |k, v| settings[k] = v }

        expect(settings.keys).to eq(expected_settings.keys)
        expected_settings.each do |expected_key, expected_value|
          expect(settings[expected_key].value).to eq(expected_value)
        end
      end
    end

    context 'when the file is deleted mid-read' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:read_file).with(subject.file).and_raise(Errno::ENOENT, 'error')
      end

      it 'raises PDK::Config::LoadError' do
        expect { subject.parse_file(subject.file) {} }.to raise_error(PDK::Config::LoadError, %r{error})
      end
    end

    context 'when the file is unreadable' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:read_file).with(subject.file).and_raise(Errno::EACCES)
      end

      it 'raises PDK::Config::LoadError' do
        expect {
          subject.parse_file(subject.file) {}
        }.to raise_error(PDK::Config::LoadError, "Unable to open #{subject.file} for reading")
      end
    end
  end

  context 'when serializing deserializing data' do
    before(:each) do
      expect(subject).to receive(:load_data).and_return(content)
    end

    it 'does not add or lose any data when round tripping the serialization' do
      # Force the file to be loaded
      expected_settings.each { |k, _| subject[k] }
      # Force a setting to be saved by setting a single known value
      expect(PDK::Util::Filesystem).to receive(:write_file).with(subject.file, content)
      key = expected_settings.keys[0]
      subject[key] = expected_settings[key]
    end
  end
end
# rubocop:enable RSpec/NamedSubject
