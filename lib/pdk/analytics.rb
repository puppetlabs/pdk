require 'securerandom'
require 'pdk/analytics/util'
require 'pdk/analytics/client/google_analytics'
require 'pdk/analytics/client/noop'

module PDK
  module Analytics
    CLIENTS = {
      noop:             Client::Noop,
      google_analytics: Client::GoogleAnalytics,
    }.freeze

    def self.build_client(opts = {})
      opts[:logger] ||= ::Logger.new(STDERR)
      opts[:client] ||= :noop

      if opts[:disabled]
        opts[:logger].debug 'Analytics opt-out is set, analytics will be disabled'
        CLIENTS[:noop].new(opts)
      else
        CLIENTS[opts[:client]].new(opts)
      end
    rescue StandardError => e
      opts[:logger].debug "Failed to initialize analytics client, analytics will be disabled: #{e}"
      CLIENTS[:noop].new(opts)
    end
  end
end
