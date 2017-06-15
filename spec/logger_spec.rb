require 'spec_helper'

describe PDK::Logger do
  context 'by default' do
    it 'prints info messages to stdout' do
      expect(STDOUT).to receive(:write).with(a_string_matching(%r{test message}))

      subject.info('test message')
    end

    it 'does not print debug messages to stdout' do
      expect(STDOUT).not_to receive(:write).with(anything)

      subject.debug('test message')
    end
  end

  context 'with debug output enabled' do
    it 'prints debug messages to stdout' do
      expect(STDOUT).to receive(:write).with(a_string_matching(%r{test debug message}))

      subject.enable_debug_output
      subject.debug('test debug message')
    end
  end
end
