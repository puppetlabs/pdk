module PDK
  module Util
    module Filesystem
      def write_file(path, content)
        raise ArgumentError unless path.is_a?(String) || path.respond_to?(:to_path)

        File.open(path, 'wb') { |f| f.write(content.encode(universal_newline: true)) }
      end
      module_function :write_file
    end
  end
end
