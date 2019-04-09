require 'securerandom'
require 'pdk/analytics/util'
require 'pdk/analytics/client/google_analytics'
require 'pdk/analytics/client/noop'

module PDK
  module Analytics
    def self.build_client(logger: ::Logger.new(STDERR))
      # TODO: PDK-1339
      config_file = File.expand_path('~/.puppetlabs/bolt/analytics.yaml')
      config = load_config(config_file)

      if config['disabled'] || ENV['PDK_DISABLE_ANALYTICS']
        logger.debug 'Analytics opt-out is set, analytics will be disabled'
        Client::Noop.new(logger)
      else
        unless config.key?('user-id')
          config['user-id'] = SecureRandom.uuid
          write_config(config_file, config)
        end

        Client::GoogleAnalytics.new(logger, config['user-id'])
      end
    rescue StandardError => e
      logger.debug "Failed to initialize analytics client, analytics will be disabled: #{e}"
      Client::Noop.new(logger)
    end

    # TODO: Extract config handling out of Analytics and pass in the parsed
    # config instead
    def self.load_config(filename)
      # TODO: Catch errors from YAML and File
      if File.exist?(filename)
        YAML.safe_load(File.read(filename))
      else
        {}
      end
    end

    def self.write_config(filename, config)
      # TODO: Catch errors from FileUtils & File
      FileUtils.mkdir_p(File.dirname(filename))
      File.write(filename, config.to_yaml)
    end
  end
end
