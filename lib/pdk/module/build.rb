require 'fileutils'
require 'minitar'
require 'zlib'
require 'pathspec'
require 'find'

module PDK
  module Module
    class Build
      def self.invoke(options = {})
        new(options).build
      end

      attr_reader :module_dir
      attr_reader :target_dir
      attr_reader :force

      def initialize(options = {})
        @module_dir = options[:module_dir] || Dir.pwd
        @target_dir = options[:target_dir] || File.join(module_dir, 'pkg')
      end

      # Read and parse the values from metadata.json for the module that is
      # being built.
      #
      # @return [Hash{String => Object}] The hash of metadata values.
      def metadata
        @metadata ||= PDK::Module::Metadata.from_file(File.join(module_dir, 'metadata.json')).data
      end

      # Return the path where the built package file will be written to.
      def package_file
        @package_file ||= File.join(target_dir, "#{release_name}.tar.gz")
      end

      # Build a module package from a module directory.
      #
      # @return [String] The path to the built package file.
      def build
        create_build_dir

        stage_module_in_build_dir
        build_package

        package_file
      ensure
        cleanup_build_dir
      end

      # Verify if there is an existing package in the target directory and prompts
      # the user if they want to overwrite it.
      def package_already_exists?
        File.exist? package_file
      end

      # Check if the module is PDK Compatible. If not, then prompt the user if
      # they want to run PDK Convert.
      def module_pdk_compatible?
        ['pdk-version', 'template-url'].any? { |key| metadata.key?(key) }
      end

      # Return the path to the temporary build directory, which will be placed
      # inside the target directory and match the release name (see #release_name).
      def build_dir
        @build_dir ||= File.join(target_dir, release_name)
      end

      # Create a temporary build directory where the files to be included in
      # the package will be staged before building the tarball.
      #
      # If the directory already exists, remove it first.
      def create_build_dir
        cleanup_build_dir

        FileUtils.mkdir_p(build_dir)
      end

      # Remove the temporary build directory and all its contents from disk.
      #
      # @return nil.
      def cleanup_build_dir
        FileUtils.rm_rf(build_dir, secure: true)
      end

      # Combine the module name and version into a Forge-compatible dash
      # separated string.
      #
      # @return [String] The module name and version, joined by a dash.
      def release_name
        @release_name ||= [
          metadata['name'],
          metadata['version'],
        ].join('-')
      end

      # Iterate through all the files and directories in the module and stage
      # them into the temporary build directory (unless ignored).
      #
      # @return nil
      def stage_module_in_build_dir
        Find.find(module_dir) do |path|
          next if path == module_dir

          ignored_path?(path) ? Find.prune : stage_path(path)
        end
      end

      # Stage a file or directory from the module into the build directory.
      #
      # @param path [String] The path to the file or directory.
      #
      # @return nil.
      def stage_path(path)
        relative_path = Pathname.new(path).relative_path_from(Pathname.new(module_dir))
        dest_path = File.join(build_dir, relative_path)

        if File.directory?(path)
          FileUtils.mkdir_p(dest_path, mode: File.stat(path).mode)
        elsif File.symlink?(path)
          warn_symlink(path)
        else
          FileUtils.cp(path, dest_path, preserve: true)
        end
      end

      # Check if the given path matches one of the patterns listed in the
      # ignore file.
      #
      # @param path [String] The path to be checked.
      #
      # @return [Boolean] true if the path matches and should be ignored.
      def ignored_path?(path)
        path = path.to_s + '/' if File.directory?(path)

        !ignored_files.match_paths([path], module_dir).empty?
      end

      # Warn the user about a symlink that would have been included in the
      # built package.
      #
      # @param path [String] The relative or absolute path to the symlink.
      #
      # @return nil.
      def warn_symlink(path)
        symlink_path = Pathname.new(path)
        module_path = Pathname.new(module_dir)

        PDK.logger.warn _('Symlinks in modules are not supported and will not be included in the package. Please investigate symlink %{from} -> %{to}.') % {
          from: symlink_path.relative_path_from(module_path),
          to:   symlink_path.realpath.relative_path_from(module_path),
        }
      end

      # Creates a gzip compressed tarball of the build directory.
      #
      # If the destination package already exists, it will be removed before
      # creating the new tarball.
      #
      # @return nil.
      def build_package
        FileUtils.rm_f(package_file)

        Dir.chdir(target_dir) do
          Zlib::GzipWriter.open(package_file) do |package_fd|
            Minitar.pack(release_name, package_fd)
          end
        end
      end

      # Select the most appropriate ignore file in the module directory.
      #
      # In order of preference, we first try `.pdkignore`, then `.pmtignore`
      # and finally `.gitignore`.
      #
      # @return [String] The path to the file containing the patterns of file
      #   paths to ignore.
      def ignore_file
        @ignore_file ||= [
          File.join(module_dir, '.pdkignore'),
          File.join(module_dir, '.pmtignore'),
          File.join(module_dir, '.gitignore'),
        ].find { |file| File.file?(file) && File.readable?(file) }
      end

      # Instantiate a new PathSpec class and populate it with the pattern(s) of
      # files to be ignored.
      #
      # @return [PathSpec] The populated ignore path matcher.
      def ignored_files
        @ignored_files ||= if ignore_file.nil?
                             PathSpec.new
                           else
                             fd = File.open(ignore_file, 'rb:UTF-8')
                             data = fd.read
                             fd.close

                             PathSpec.new(data)
                           end
      end
    end
  end
end
