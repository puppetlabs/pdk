require 'spec_helper'

describe PDK::Logger do
  context 'by default' do
    it 'should print info messages to stdout' do
      expect(STDOUT).to receive(:write).with(a_string_matching(/test message/))

      subject.info('test message')
    end

    it 'should not print debug messages to stdout' do
      expect(STDOUT).to_not receive(:write).with(anything)

      subject.debug('test message')
    end
  end

  context 'with debug output enabled' do
    it 'should print debug messages to stdout' do
      expect(STDOUT).to receive(:write).with(a_string_matching(/test debug message/))

      subject.enable_debug_output
      subject.debug('test debug message')
    end
  end
end
