require 'securerandom'
require 'pdk/analytics/util'
require 'pdk/analytics/client/google_analytics'
require 'pdk/analytics/client/noop'

module PDK
  module Analytics
    def self.build_client(logger: ::Logger.new(STDERR), disabled:, uuid:)
      if disabled
        logger.debug 'Analytics opt-out is set, analytics will be disabled'
        Client::Noop.new(logger)
      else
        Client::GoogleAnalytics.new(logger, uuid)
      end
    rescue StandardError => e
      logger.debug "Failed to initialize analytics client, analytics will be disabled: #{e}"
      Client::Noop.new(logger)
    end
  end
end
