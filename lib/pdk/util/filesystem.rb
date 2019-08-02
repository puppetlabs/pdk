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

      def read_file(file, nil_on_error: false)
        File.read(file)
      rescue => e
        raise e unless nil_on_error
        nil
      end
      module_function :read_file

      #:nocov:
      # These methods just wrap core Ruby functionality and
      # can be ignored for code coverage
      def directory?(*args)
        File.directory?(*args)
      end
      module_function :directory?

      def file?(*args)
        File.file?(*args)
      end
      module_function :file?

      def expand_path(*args)
        File.expand_path(*args)
      end
      module_function :expand_path

      def glob(*args)
        Dir.glob(*args)
      end
      module_function :glob

      def fnmatch(*args)
        File.fnmatch(*args)
      end
      module_function :fnmatch

      def readable?(*args)
        File.readable?(*args)
      end
      module_function :readable?
      #:nocov:
    end
  end
end
