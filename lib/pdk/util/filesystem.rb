module PDK
  module Util
    module Filesystem
      def write_file(path, content)
        raise ArgumentError unless path.is_a?(String) || path.respond_to?(:to_path)

        # Harmonize newlines across platforms.
        content = content.encode(universal_newline: true)

        # Make sure all written files have a trailing newline.
        content += "\n" unless content[-1] == "\n"

        File.open(path, 'wb') { |f| f.write(content) }
      end
      module_function :write_file
    end
  end
end
