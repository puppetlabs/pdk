require 'pdk'
autoload :FileUtils, 'fileutils'

module PDK
  module Util
    module Filesystem
      def write_file(path, content)
        raise ArgumentError, 'content must be a String' unless content.is_a?(String)
        raise ArgumentError, 'path must be a String or Pathname' unless path.is_a?(String) || path.respond_to?(:to_path)

        # Harmonize newlines across platforms.
        content = content.encode(universal_newline: true)

        # Make sure all written files have a trailing newline.
        content += "\n" unless content[-1] == "\n"

        File.binwrite(path, content)
      end
      module_function :write_file

      def read_file(file, nil_on_error: false, open_args: 'r')
        File.read(file, open_args: Array(open_args))
      rescue StandardError => e
        raise e unless nil_on_error

        nil
      end
      module_function :read_file

      def make_executable(file)
        FileUtils.chmod('a+x', file)
      end
      module_function :make_executable

      # :nocov:
      # These methods just wrap core Ruby functionality and
      # can be ignored for code coverage
      def directory?(*args)
        File.directory?(*args)
      end
      module_function :directory?

      def mkdir_p(*args, **kwargs)
        FileUtils.mkdir_p(*args, **kwargs)
      end
      module_function :mkdir_p

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

      def fnmatch?(*args)
        File.fnmatch?(*args)
      end
      module_function :fnmatch?

      def readable?(*args)
        File.readable?(*args)
      end
      module_function :readable?

      def exist?(*args)
        File.exist?(*args)
      end
      module_function :exist?

      def rm(*args, **kwargs)
        FileUtils.rm(*args, **kwargs)
      end
      module_function :rm

      def rm_f(*args, **kwargs)
        FileUtils.rm_f(*args, **kwargs)
      end
      module_function :rm_f

      def rm_rf(*args, **kwargs)
        FileUtils.rm_rf(*args, **kwargs)
      end
      module_function :rm_rf

      def remove_entry_secure(*args)
        FileUtils.remove_entry_secure(*args)
      end
      module_function :remove_entry_secure

      def zero?(*args)
        File.empty?(*args)
      end
      module_function :zero?

      def stat(*args)
        File.stat(*args)
      end
      module_function :stat

      def symlink?(*args)
        File.symlink?(*args)
      end
      module_function :symlink?

      def cp(*args, **kwargs)
        FileUtils.cp(*args, **kwargs)
      end
      module_function :cp

      def mv(*args, **kwargs)
        FileUtils.mv(*args, **kwargs)
      rescue Errno::ENOENT
        # PDK-1169 - FileUtils.mv raises Errno::ENOENT when moving files inside
        #            VMWare shared folders on Windows. So we need to catch this
        #            case, check if the file exists to see if the exception is
        #            legit and "move" the file with cp & rm.
        src, dest, opts = args
        raise unless File.exist?(src)

        FileUtils.cp(src, dest, preserve: true)
        if (opts ||= {})[:secure]
          FileUtils.remove_entry_secure(src, opts[:force])
        else
          FileUtils.remove_entry(src, opts[:force])
        end
      end
      module_function :mv

      def executable?(*args)
        File.executable?(*args)
      end
      module_function :executable?
      # :nocov:
    end
  end
end
