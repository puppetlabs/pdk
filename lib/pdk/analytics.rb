require 'pdk/analytics/client/google_analytics'
require 'pdk/analytics/client/noop'

module PDK
  def self.analytics
    require 'pdk/config'
    require 'pdk/logger'
    require 'pdk/util'
    require 'pdk/version'

    @analytics ||= PDK::Analytics.build_client(
      logger:        PDK.logger,
      disabled:      ENV['PDK_DISABLE_ANALYTICS'] || PDK.config.user['analytics']['disabled'],
      user_id:       PDK.config.user['analytics']['user-id'],
      app_id:        "UA-139917834-#{PDK::Util.development_mode? ? '2' : '1'}",
      client:        :google_analytics,
      app_name:      'pdk',
      app_version:   PDK::VERSION,
      app_installer: PDK::Util.package_install? ? 'package' : 'gem',
    )
  end

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
