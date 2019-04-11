require 'pdk/config/namespace'

module PDK
  class Config
    class JSON < Namespace
      def parse_data(data, _filename)
        return {} if data.nil? || data.empty?

        require 'json'

        ::JSON.parse(data)
      rescue ::JSON::ParserError => e
        raise PDK::Config::LoadError, e.message
      end

      def serialize_data(data)
        require 'json'

        ::JSON.pretty_generate(data)
      end
    end
  end
end
