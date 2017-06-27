require 'spec_helper'

describe PDK::Logger do
  subject(:pdk_logger) { described_class.new }

  context 'by default' do
    it 'prints info messages to stdout' do
      expect(STDOUT).to receive(:write).with(a_string_matching(%r{test message}))

      pdk_logger.info('test message')
    end

    it 'does not print debug messages to stdout' do
      expect(STDOUT).not_to receive(:write).with(anything)

      pdk_logger.debug('test message')
    end
  end

  context 'with debug output enabled' do
    it 'prints debug messages to stdout' do
      expect(STDOUT).to receive(:write).with(a_string_matching(%r{test debug message}))

      pdk_logger.enable_debug_output
      pdk_logger.debug('test debug message')
    end
  end
end
