require 'pdk'

module PDK
  module Module
    class Build
      def self.invoke(options = {})
        new(options).build
      end

      attr_reader :module_dir
      attr_reader :target_dir

      def initialize(options = {})
        @module_dir = PDK::Util::Filesystem.expand_path(options[:module_dir] || Dir.pwd)
        @target_dir = PDK::Util::Filesystem.expand_path(options[:'target-dir'] || File.join(module_dir, 'pkg'))
      end

      # Read and parse the values from metadata.json for the module that is
      # being built.
      #
      # @return [Hash{String => Object}] The hash of metadata values.
      def metadata
        require 'pdk/module/metadata'

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
        PDK::Util::Filesystem.exist?(package_file)
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

        PDK::Util::Filesystem.mkdir_p(build_dir)
      end

      # Remove the temporary build directory and all its contents from disk.
      #
      # @return nil.
      def cleanup_build_dir
        PDK::Util::Filesystem.rm_rf(build_dir, secure: true)
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
        require 'find'

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
        require 'pathname'

        relative_path = Pathname.new(path).relative_path_from(Pathname.new(module_dir))
        dest_path = File.join(build_dir, relative_path)

        validate_path_encoding!(relative_path.to_path)

        if PDK::Util::Filesystem.directory?(path)
          PDK::Util::Filesystem.mkdir_p(dest_path, mode: PDK::Util::Filesystem.stat(path).mode)
        elsif PDK::Util::Filesystem.symlink?(path)
          warn_symlink(path)
        else
          validate_ustar_path!(relative_path.to_path)
          PDK::Util::Filesystem.cp(path, dest_path, preserve: true)
        end
      rescue ArgumentError => e
        raise PDK::CLI::ExitWithError, '%{message} Rename the file or exclude it from the package ' \
                                       'by adding it to the .pdkignore file in your module.' % { message: e.message }
      end

      # Check if the given path matches one of the patterns listed in the
      # ignore file.
      #
      # @param path [String] The path to be checked.
      #
      # @return [Boolean] true if the path matches and should be ignored.
      def ignored_path?(path)
        path = path.to_s + '/' if PDK::Util::Filesystem.directory?(path)

        !ignored_files.match_paths([path], module_dir).empty?
      end

      # Warn the user about a symlink that would have been included in the
      # built package.
      #
      # @param path [String] The relative or absolute path to the symlink.
      #
      # @return nil.
      def warn_symlink(path)
        require 'pathname'

        symlink_path = Pathname.new(path)
        module_path = Pathname.new(module_dir)

        PDK.logger.warn 'Symlinks in modules are not supported and will not be included in the package. Please investigate symlink %{from} -> %{to}.' % {
          from: symlink_path.relative_path_from(module_path),
          to:   symlink_path.realpath.relative_path_from(module_path),
        }
      end

      # Checks if the path length will fit into the POSIX.1-1998 (ustar) tar
      # header format.
      #
      # POSIX.1-2001 (which allows paths of infinite length) was adopted by GNU
      # tar in 2004 and is supported by minitar 0.7 and above. Unfortunately
      # much of the Puppet ecosystem still uses minitar 0.6.1.
      #
      # POSIX.1-1998 tar format does not allow for paths greater than 256 bytes,
      # or paths that can't be split into a prefix of 155 bytes (max) and
      # a suffix of 100 bytes (max).
      #
      # This logic was pretty much copied from the private method
      # {Archive::Tar::Minitar::Writer#split_name}.
      #
      # @param path [String] the relative path to be added to the tar file.
      #
      # @raise [ArgumentError] if the path is too long or could not be split.
      #
      # @return [nil]
      def validate_ustar_path!(path)
        if path.bytesize > 256
          raise ArgumentError, "The path '%{path}' is longer than 256 bytes." % {
            path: path,
          }
        end

        if path.bytesize <= 100
          prefix = ''
        else
          parts = path.split(File::SEPARATOR)
          newpath = parts.pop
          nxt = ''

          loop do
            nxt = parts.pop || ''
            break if newpath.bytesize + 1 + nxt.bytesize >= 100
            newpath = File.join(nxt, newpath)
          end

          prefix = File.join(*parts, nxt)
          path = newpath
        end

        return unless path.bytesize > 100 || prefix.bytesize > 155

        raise ArgumentError,
              "'%{path}' could not be split at a directory separator into two " \
              'parts, the first having a maximum length of 155 bytes and the ' \
              'second having a maximum length of 100 bytes.' % { path: path }
      end

      # Checks if the path contains any non-ASCII characters.
      #
      # Java will throw an error when it encounters a path containing
      # characters that are not supported by the hosts locale. In order to
      # maximise compatibility we limit the paths to contain only ASCII
      # characters, which should be part of any locale character set.
      #
      # @param path [String] the relative path to be added to the tar file.
      #
      # @raise [ArgumentError] if the path contains non-ASCII characters.
      #
      # @return [nil]
      def validate_path_encoding!(path)
        return unless path =~ %r{[^\x00-\x7F]}

        raise ArgumentError, "'%{path}' can only include ASCII characters in its path or " \
                             'filename in order to be compatible with a wide range of hosts.' % { path: path }
      end

      # Creates a gzip compressed tarball of the build directory.
      #
      # If the destination package already exists, it will be removed before
      # creating the new tarball.
      #
      # @return nil.
      def build_package
        require 'zlib'
        require 'minitar'
        require 'find'

        PDK::Util::Filesystem.rm_f(package_file)

        Dir.chdir(target_dir) do
          begin
            gz = Zlib::GzipWriter.new(File.open(package_file, 'wb')) # rubocop:disable PDK/FileOpen
            tar = Minitar::Output.new(gz)
            Find.find(release_name) do |entry|
              entry_meta = {
                name: entry,
              }

              orig_mode = PDK::Util::Filesystem.stat(entry).mode
              min_mode = Minitar.dir?(entry) ? 0o755 : 0o644

              entry_meta[:mode] = orig_mode | min_mode

              if entry_meta[:mode] != orig_mode
                PDK.logger.debug('Updated permissions of packaged \'%{entry}\' to %{new_mode}' % {
                  entry: entry,
                  new_mode: (entry_meta[:mode] & 0o7777).to_s(8),
                })
              end

              Minitar.pack_file(entry_meta, tar)
            end
          ensure
            tar.close
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
        ].find { |file| PDK::Util::Filesystem.file?(file) && PDK::Util::Filesystem.readable?(file) }
      end

      # Instantiate a new PathSpec class and populate it with the pattern(s) of
      # files to be ignored.
      #
      # @return [PathSpec] The populated ignore path matcher.
      def ignored_files
        require 'pdk/module'
        require 'pathspec'

        @ignored_files ||=
          begin
            ignored = if ignore_file.nil?
                        PathSpec.new
                      else
                        PathSpec.new(PDK::Util::Filesystem.read_file(ignore_file, open_args: 'rb:UTF-8'))
                      end

            if File.realdirpath(target_dir).start_with?(File.realdirpath(module_dir))
              ignored = ignored.add("\/#{File.basename(target_dir)}\/")
            end

            PDK::Module::DEFAULT_IGNORED.each { |r| ignored.add(r) }

            ignored
          end
      end
    end
  end
end
