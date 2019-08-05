require 'pdk/config/namespace'
require 'pdk/config/setting'

module PDK
  class Config
    class YAML < Namespace
      def parse_file(filename)
        data = load_data(filename)
        return if data.nil? || data.empty?

        require 'yaml'

        data = ::YAML.safe_load(data, [Symbol], [], true)
        return if data.nil?

        data.each { |k, v| yield k, PDK::Config::Setting.new(k, self, v) }
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
