require 'pdk'

module PDK
  module Analytics
    module Util
      def self.fetch_os_async
        require 'concurrent/configuration'
        require 'concurrent/future'

        Concurrent::Future.execute(executor: :io) do
          require 'facter'
          os = Facter.value('os')

          os.nil? ? 'unknown' : "#{os['name']} #{os.fetch('release', {}).fetch('major', '')}".strip
        end
      end
    end
  end
end
