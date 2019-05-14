require 'pdk/config/namespace'

module PDK
  class Config
    class YAML < Namespace
      def parse_data(data, filename)
        return {} if data.nil? || data.empty?

        require 'yaml'

        ::YAML.safe_load(data, [Symbol], [], true)
      rescue Psych::SyntaxError => e
        raise PDK::Config::LoadError, _('Syntax error when loading %{file}: %{error}') % {
          file:  filename,
          error: "#{e.problem} #{e.context}",
        }
      rescue Psych::DisallowedClass => e
        raise PDK::Config::LoadError, _('Unsupported class in %{file}: %{error}') % {
          file:  filename,
          error: e.message,
        }
      end

      def serialize_data(data)
        require 'yaml'

        ::YAML.dump(data)
      end
    end
  end
end
