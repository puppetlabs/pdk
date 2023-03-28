require 'spec_helper'
require 'securerandom'
require 'httpclient'
require 'concurrent/configuration'
require 'concurrent/future'
require 'locale'
require 'pdk/analytics/client/google_analytics'

describe PDK::Analytics::Client::GoogleAnalytics do
  subject(:client) { described_class.new(options) }

  let(:options) do
    {
      logger: logger,
      app_name: 'pdk',
      app_id: 'UA-xxxx-1',
      app_version: PDK::VERSION,
      user_id: uuid,
    }
  end

  let(:uuid) { SecureRandom.uuid }
  let(:base_params) do
    {
      v: described_class::PROTOCOL_VERSION,
      an: options[:app_name],
      av: options[:app_version],
      cid: options[:user_id],
      tid: options[:app_id],
      aiid: options[:app_installer],
      ul: Locale.current.to_rfc,
      aip: true,
      cd1: os_name,
    }
  end
  let(:mock_httpclient) { instance_double(HTTPClient) }
  let(:ga_url) { described_class::TRACKING_URL }
  let(:executor) { Concurrent.new_io_executor }
  let(:logger) { instance_double(Logger, debug: true) }
  let(:os_name) { 'CentOS 7' }

  before do
    allow(PDK::Analytics::Util).to receive(:fetch_os_async).and_return(instance_double(Concurrent::Future, value: os_name))
    allow(HTTPClient).to receive(:new).and_return(mock_httpclient)
    allow(Concurrent).to receive(:global_io_executor).and_return(executor)
  end

  describe '#screen_view' do
    after do
      client.finish
    end

    it 'properly formats the screenview' do
      params = base_params.merge(t: 'screenview', cd: 'job_run')

      expect(mock_httpclient).to receive(:post).with(ga_url, params).and_return(true)

      client.screen_view('job_run')
    end

    it 'sets custom dimensions correctly' do
      params = base_params.merge(t: 'screenview', cd: 'job_run', cd1: 'CentOS 7', cd2: 'text')

      expect(mock_httpclient).to receive(:post).with(ga_url, params).and_return(true)

      client.screen_view('job_run', operating_system: 'CentOS 7', output_format: 'text')
    end

    it 'raises an error if an unknown custom dimension is specified' do
      expect { client.screen_view('job_run', random_field: 'foo') }.to raise_error(%r{Unknown analytics key})
    end
  end

  describe '#event' do
    after do
      client.finish
    end

    it 'properly formats the event' do
      params = base_params.merge(t: 'event', ec: 'run', ea: 'task')

      expect(mock_httpclient).to receive(:post).with(ga_url, params).and_return(true)

      client.event('run', 'task')
    end

    it 'sends the event label if supplied' do
      params = base_params.merge(t: 'event', ec: 'run', ea: 'task', el: 'happy')

      expect(mock_httpclient).to receive(:post).with(ga_url, params).and_return(true)

      client.event('run', 'task', label: 'happy')
    end

    it 'sends the event metric if supplied' do
      params = base_params.merge(t: 'event', ec: 'run', ea: 'task', ev: 12)

      expect(mock_httpclient).to receive(:post).with(ga_url, params).and_return(true)

      client.event('run', 'task', value: 12)
    end
  end
end
