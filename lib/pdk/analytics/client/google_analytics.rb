require 'pdk'

module PDK
  module Analytics
    module Client
      class GoogleAnalytics
        PROTOCOL_VERSION  = 1
        TRACKING_URL      = 'https://google-analytics.com/collect'.freeze
        CUSTOM_DIMENSIONS = {
          operating_system: :cd1,
          output_format:    :cd2,
          ruby_version:     :cd3,
          cli_options:      :cd4,
          env_vars:         :cd5,
        }.freeze

        attr_reader :user_id
        attr_reader :logger
        attr_reader :app_name
        attr_reader :app_id
        attr_reader :app_version
        attr_reader :app_installer

        def initialize(opts)
          # lazy-load expensive gem code
          require 'concurrent/configuration'
          require 'concurrent/future'
          require 'httpclient'
          require 'locale'
          require 'pdk/analytics/util'

          @http = HTTPClient.new
          @user_id = opts[:user_id]
          @executor = Concurrent.global_io_executor
          @os = PDK::Analytics::Util.fetch_os_async
          @logger = opts[:logger]
          @app_name = opts[:app_name]
          @app_id = opts[:app_id]
          @app_version = opts[:app_version]
          @app_installer = opts[:app_installer]
        end

        def screen_view(screen, **kwargs)
          custom_dimensions = walk_keys(kwargs) do |k|
            CUSTOM_DIMENSIONS[k] || raise("Unknown analytics key '%{key}'" % { key: k })
          end

          screen_view_params = {
            # Type
            t:  'screenview',
            # Screen Name
            cd: screen,
          }.merge(custom_dimensions)

          submit(base_params.merge(screen_view_params))
        end

        def event(category, action, label: nil, value: nil, **kwargs)
          custom_dimensions = walk_keys(kwargs) do |k|
            CUSTOM_DIMENSIONS[k] || raise("Unknown analytics key '%{key}'" % { key: k })
          end

          event_params = {
            # Type
            t:  'event',
            # Event Category
            ec: category,
            # Event Action
            ea: action,
          }.merge(custom_dimensions)

          # Event Label
          event_params[:el] = label if label
          # Event Value
          event_params[:ev] = value if value

          submit(base_params.merge(event_params))
        end

        def submit(params)
          # Handle analytics submission in the background to avoid blocking the
          # app or polluting the log with errors
          Concurrent::Future.execute(executor: @executor) do
            require 'json'

            logger.debug "Submitting analytics: #{JSON.pretty_generate(params)}"
            @http.post(TRACKING_URL, params)
            logger.debug 'Completed analytics submission'
          end
        end

        # These parameters have terrible names. See this page for complete documentation:
        # https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters
        def base_params
          require 'locale'

          {
            v:    PROTOCOL_VERSION,
            # Client ID
            cid:  user_id,
            # Tracking ID
            tid:  app_id,
            # Application Name
            an:   app_name,
            # Application Version
            av:   app_version,
            # Application Installer ID
            aiid: app_installer,
            # Anonymize IPs
            aip:  true,
            # User locale
            ul:   Locale.current.to_rfc,
            # Custom Dimension 1 (Operating System)
            cd1:  @os.value,
          }
        end

        # If the user is running a very fast command, there may not be time for
        # analytics submission to complete before the command is finished. In
        # that case, we give a little buffer for any stragglers to finish up.
        # 250ms strikes a balance between accomodating slower networks while not
        # introducing a noticeable "hang".
        def finish
          @executor.shutdown
          @executor.wait_for_termination(0.25)
        end

        private

        def walk_keys(data, &block)
          if data.is_a?(Hash)
            data.each_with_object({}) do |(k, v), acc|
              v = walk_keys(v, &block)
              acc[yield(k)] = v
            end
          elsif data.is_a?(Array)
            data.map { |v| walk_keys(v, &block) }
          else
            data
          end
        end
      end
    end
  end
end
