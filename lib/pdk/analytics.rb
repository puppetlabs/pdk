require 'pdk'

module PDK
  def self.analytics
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
