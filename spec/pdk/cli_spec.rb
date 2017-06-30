require 'spec_helper'

describe PDK::CLI do
  context 'when provided an invalid report format' do
    it 'informs the user and exits' do
      expect(logger).to receive(:fatal).with(a_string_matching(%r{'non_existant_format'.*valid report format}))

      expect {
        described_class.run(['--format', 'non_existant_format'])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).not_to eq(0)
      }
    end
  end

  context 'when provided a valid report format' do
    it 'does not exit early with an error' do
      expect(logger).not_to receive(:fatal).with(a_string_matching(%r{valid report format}))
      allow($stdout).to receive(:puts).with(anything)

      described_class.run(['--format', 'text'])
    end
  end

  context 'when not provided any report formats' do
    it 'does not exit early with an error' do
      expect(logger).not_to receive(:fatal).with(a_string_matching(%r{valid report format}))
      allow($stdout).to receive(:puts).with(anything)

      described_class.run([])
    end
  end
end
