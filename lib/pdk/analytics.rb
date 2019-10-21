require 'pdk'

autoload :Logger, 'logger'

module PDK
  module Analytics
    autoload :Util, 'pdk/analytics/util'

    module Client
      autoload :Noop, 'pdk/analytics/client/noop'
      autoload :GoogleAnalytics, 'pdk/analytics/client/google_analytics'
    end

    def self.build_client(opts = {})
      opts[:logger] ||= ::Logger.new(STDERR)
      opts[:client] ||= :noop

      if opts[:disabled]
        opts[:logger].debug 'Analytics opt-out is set, analytics will be disabled'
        opts[:client] = :noop
      end

      client_const = opts[:client].to_s.split('_').map(&:capitalize).join
      PDK::Analytics::Client.const_get(client_const).new(opts)
    rescue StandardError => e
      opts[:logger].debug "Failed to initialize analytics client, analytics will be disabled: #{e}"
      PDK::Analytics::Client::Noop.new(opts)
    end
  end
end
