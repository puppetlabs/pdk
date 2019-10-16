require 'pdk'

module PDK
  class Config
    class JSON < Namespace
      # Parses a JSON document.
      #
      # @see PDK::Config::Namespace.parse_file
      def parse_file(filename)
        raise unless block_given?
        data = load_data(filename)
        return if data.nil? || data.empty?

        require 'json'

        data = ::JSON.parse(data)
        return if data.nil? || data.empty?

        data.each { |k, v| yield k, PDK::Config::Setting.new(k, self, v) }
      rescue ::JSON::ParserError => e
        raise PDK::Config::LoadError, e.message
      end

      # Serializes object data into a JSON string.
      #
      # @see PDK::Config::Namespace.serialize_data
      def serialize_data(data)
        require 'json'

        ::JSON.pretty_generate(data)
      end
    end
  end
end
