require 'pdk'

module PDK
  class Config
    # Parses a YAML document.
    #
    # @see PDK::Config::Namespace.parse_file
    class YAML < Namespace
      def parse_file(filename)
        raise unless block_given?
        data = load_data(filename)
        return if data.nil? || data.empty?

        require 'yaml'

        data = if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.1.0.pre1')
                 ::YAML.safe_load(data, permitted_classes: [Symbol], permitted_symbols: [], aliases: true)
               else
                 ::YAML.safe_load(data, [Symbol], [], true)
               end
        return if data.nil?

        data.each { |k, v| yield k, PDK::Config::Setting.new(k, self, v) }
      rescue Psych::SyntaxError => e
        raise PDK::Config::LoadError, 'Syntax error when loading %{file}: %{error}' % {
          file:  filename,
          error: "#{e.problem} #{e.context}",
        }
      rescue Psych::DisallowedClass => e
        raise PDK::Config::LoadError, 'Unsupported class in %{file}: %{error}' % {
          file:  filename,
          error: e.message,
        }
      end

      # Serializes object data into a YAML string.
      #
      # @see PDK::Config::Namespace.serialize_data
      def serialize_data(data)
        require 'yaml'

        ::YAML.dump(data)
      end
    end
  end
end
