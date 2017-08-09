require 'spec_helper'

describe PDK::Logger do
  subject(:pdk_logger) { described_class.new }

  context 'by default' do
    it 'prints info messages to stdout' do
      expect(STDERR).to receive(:write).with(a_string_matching(%r{test message}))

      pdk_logger.info('test message')
    end

    it 'does not print debug messages to stdout' do
      expect(STDERR).not_to receive(:write).with(anything)

      pdk_logger.debug('test message')
    end

    it { is_expected.to have_attributes(debug?: false) }
  end

  context 'with debug output enabled' do
    before(:each) do
      pdk_logger.enable_debug_output
    end

    it 'prints debug messages to stdout' do
      expect(STDERR).to receive(:write).with(a_string_matching(%r{test debug message}))

      pdk_logger.debug('test debug message')
    end

    it { is_expected.to have_attributes(debug?: true) }
  end
end
