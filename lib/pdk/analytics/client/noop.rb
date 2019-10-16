require 'pdk'

module PDK
  module Analytics
    module Client
      class Noop
        attr_reader :logger

        def initialize(opts)
          @logger = opts[:logger]
        end

        def screen_view(screen, **_kwargs)
          logger.debug "Skipping submission of '#{screen}' screenview because analytics is disabled"
        end

        def event(category, action, **_kwargs)
          logger.debug "Skipping submission of '#{category} #{action}' event because analytics is disabled"
        end

        def finish; end
      end
    end
  end
end
