require 'spec_helper'

describe PDK::Analytics::Client::Noop do
  subject(:client) { described_class.new(logger) }

  let(:logger) { instance_double(Logger, debug: true) }

  describe '#screen_view' do
    it 'does not raise an error' do
      expect { client.screen_view('job_run') }.not_to raise_error
    end
  end

  describe '#event' do
    it 'does not raise an error' do
      expect { client.event('run', 'task') }.not_to raise_error
    end

    context 'with a label' do
      it 'does not raise an error' do
        expect { client.event('run', 'task', label: 'happy') }.not_to raise_error
      end
    end

    context 'with a value' do
      it 'does not raise an error' do
        expect { client.event('run', 'task', value: 12) }.not_to raise_error
      end
    end
  end

  describe '#finish' do
    it 'does not raise an error' do
      expect { client.finish }.not_to raise_error
    end
  end
end
