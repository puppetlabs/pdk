require 'pdk'

module PDK
  module Module
    class UpdateManager
      # Initialises a blank UpdateManager object, which is used to store and
      # process file additions/removals/modifications.
      def initialize
        require 'set'

        @modified_files = Set.new
        @added_files = Set.new
        @removed_files = Set.new
        @diff_cache = {}
      end

      # Store a pending modification to an existing file.
      #
      # @param path [String] The path to the file to be modified.
      # @param content [String] The new content of the file.
      def modify_file(path, content)
        @modified_files << { path: path, content: content }
      end

      # Store a pending file addition.
      #
      # @param path [String] The path where the file will be created.
      # @param content [String] The content of the new file.
      def add_file(path, content)
        @added_files << { path: path, content: content }
      end

      # Store a pending file removal.
      #
      # @param path [String] The path to the file to be removed.
      def remove_file(path)
        @removed_files << path
      end

      # Generate a summary of the changes that will be applied to the module.
      #
      # @raise (see #calculate_diffs)
      # @return [Hash{Symbol => Set,Hash}] the summary of the pending changes.
      def changes
        require 'pdk/util/filesystem'

        calculate_diffs

        {
          added:    @added_files,
          removed:  @removed_files.select { |f| PDK::Util::Filesystem.exist?(f) },
          modified: @diff_cache.reject { |_, value| value.nil? },
        }
      end

      # Check if there are any pending changes to apply to the module.
      #
      # @raise (see #changes)
      # @return [Boolean] true if there are changes to apply to the module.
      def changes?
        !changes[:added].empty? ||
          !changes[:removed].empty? ||
          changes[:modified].any? { |_, value| !value.nil? }
      end

      # Check if the update manager will change the specified file upon sync.
      #
      # @param path [String] The path to the file.
      #
      # @raise (see #changes)
      # @return [Boolean] true if the file will be changed.
      def changed?(path)
        changes[:added].any? { |add| add[:path] == path } ||
          changes[:removed].include?(path) ||
          changes[:modified].key?(path)
      end

      def clear!
        @modified_files.clear
        @added_files.clear
        @removed_files.clear
        nil
      end

      # Apply any pending changes stored in the UpdateManager to the module.
      #
      # @raise (see #calculate_diffs)
      # @raise (see #write_file)
      # @raise (see #unlink_file)
      def sync_changes!
        calculate_diffs

        files_to_write = @added_files
        files_to_write += @modified_files.reject { |file| @diff_cache[file[:path]].nil? }

        @removed_files.each do |file|
          unlink_file(file)
        end

        files_to_write.each do |file|
          write_file(file[:path], file[:content])
        end
      end

      # Remove a file from disk.
      #
      # Like FileUtils.rm_f, this method will not fail if the file does not
      # exist. Unlike FileUtils.rm_f, this method will not blindly swallow all
      # exceptions.
      #
      # @param path [String] The path to the file to be removed.
      #
      # @raise [PDK::CLI::ExitWithError] if the file could not be removed.
      def unlink_file(path)
        require 'pdk/util/filesystem'

        if PDK::Util::Filesystem.file?(path)
          PDK.logger.debug("unlinking '%{path}'" % { path: path })
          PDK::Util::Filesystem.rm(path)
        else
          PDK.logger.debug("'%{path}': already gone" % { path: path })
        end
      rescue => e
        raise PDK::CLI::ExitWithError, "Unable to remove '%{path}': %{message}" % {
          path:    path,
          message: e.message,
        }
      end

      private

      # Loop through all the files to be modified and cache of unified diff of
      # the changes to be made to each file.
      #
      # @raise [PDK::CLI::ExitWithError] if a file being modified isn't
      #   readable.
      def calculate_diffs
        require 'pdk/util/filesystem'

        @modified_files.each do |file|
          next if @diff_cache.key?(file[:path])

          unless PDK::Util::Filesystem.readable?(file[:path])
            raise PDK::CLI::ExitWithError, "Unable to open '%{path}' for reading" % { path: file[:path] }
          end

          old_content = PDK::Util::Filesystem.read_file(file[:path])
          file_diff = unified_diff(file[:path], old_content, file[:content])
          @diff_cache[file[:path]] = file_diff
        end
      end

      # Write or overwrite a file with the specified content.
      #
      # @param path [String] The path to be written to.
      # @param content [String] The data to be written to the file.
      #
      # @raise [PDK::CLI::ExitWithError] if the file is not writeable.
      def write_file(path, content)
        require 'pdk/util/filesystem'

        PDK::Util::Filesystem.mkdir_p(File.dirname(path))
        PDK.logger.debug("writing '%{path}'" % { path: path })
        PDK::Util::Filesystem.write_file(path, content)
      rescue Errno::EACCES
        raise PDK::CLI::ExitWithError, "You do not have permission to write to '%{path}'" % { path: path }
      end

      # Generate a unified diff of the changes to be made to a file.
      #
      # @param path [String] The path to the file being diffed (only used to
      #   generate the diff header).
      # @param old_content [String] The current content of the file.
      # @param new_content [String] The new content of the file if the pending
      #   change is applied.
      # @param lines_of_context [Integer] The maximum number of lines of
      #   context to include around the changed lines in the diff output
      #   (default: 3).
      #
      # @return [String] The unified diff of the pending changes to the file.
      def unified_diff(path, old_content, new_content, lines_of_context = 3)
        require 'diff/lcs'
        require 'English'

        output = []

        old_lines = old_content.split($INPUT_RECORD_SEPARATOR).map(&:chomp)
        new_lines = new_content.split($INPUT_RECORD_SEPARATOR).map(&:chomp)

        diffs = Diff::LCS.diff(old_lines, new_lines)

        return if diffs.empty?

        require 'diff/lcs/hunk'

        file_mtime = PDK::Util::Filesystem.stat(path).mtime.localtime.strftime('%Y-%m-%d %H:%M:%S.%N %z')
        now = Time.now.localtime.strftime('%Y-%m-%d %H:%M:%S.%N %z')

        output << "--- #{path}\t#{file_mtime}"
        output << "+++ #{path}.pdknew\t#{now}"

        oldhunk = hunk = nil
        file_length_difference = 0

        diffs.each do |piece|
          begin
            hunk = Diff::LCS::Hunk.new(old_lines, new_lines, piece, lines_of_context, file_length_difference)
            file_length_difference = hunk.file_length_difference

            next unless oldhunk

            # If the hunk overlaps with the oldhunk, merge them.
            next if lines_of_context > 0 && hunk.merge(oldhunk)

            output << oldhunk.diff(:unified)
          ensure
            oldhunk = hunk
          end
        end

        output << oldhunk.diff(:unified)

        output.join($INPUT_RECORD_SEPARATOR)
      end
    end
  end
end
