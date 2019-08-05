require 'pdk/config/namespace'

module PDK
  class Config
    class JSON < Namespace
      def parse_file(filename)
        data = load_data(filename)
        return if data.nil? || data.empty?

        require 'json'

        data = ::JSON.parse(data)
        return if data.nil? || data.empty?

        data.each { |k, v| yield k, PDK::Config::Setting.new(k, self, v) }
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
