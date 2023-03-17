require 'spec_helper'
require 'pdk/logger'

describe PDK::Logger do
  subject(:pdk_logger) { described_class.new }

  context 'by default' do
    it 'prints info messages to stdout' do
      expect($stderr).to receive(:write).with(a_string_matching(%r{test message}))

      pdk_logger.info('test message')
    end

    it 'does not print debug messages to stdout' do
      expect($stderr).not_to receive(:write).with(anything)

      pdk_logger.debug('test message')
    end

    it { is_expected.to have_attributes(debug?: false) }
  end

  context 'with debug output enabled' do
    before(:each) do
      pdk_logger.enable_debug_output
    end

    it 'prints debug messages to stdout' do
      expect($stderr).to receive(:write).with(a_string_matching(%r{test debug message}))

      pdk_logger.debug('test debug message')
    end

    it { is_expected.to have_attributes(debug?: true) }
  end

  describe '#warn_once' do
    it 'only sends each message once' do
      expect($stderr).to receive(:write).with("pdk (WARN): message 1\n").once

      pdk_logger.warn_once('message 1')
      pdk_logger.warn_once('message 1')
    end
  end
end
