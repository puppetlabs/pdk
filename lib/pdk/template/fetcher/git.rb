require 'pdk'

module PDK
  module Template
    module Fetcher
      class Git < PDK::Template::Fetcher::AbstractFetcher
        # Whether the passed uri is fetchable by Git.
        # @see PDK::Template::Fetcher.instance
        # @return [Boolean]
        def self.fetchable?(uri, _options = {})
          PDK::Util::Git.repo?(uri.bare_uri)
        end

        # @see PDK::Template::Fetcher::AbstractTemplateFetcher.fetch!
        def fetch!
          return if fetched
          super

          # Default metadata for all git fetching methods
          @metadata['template-url'] = uri.metadata_format

          # We don't do a checkout of local-path repos. There are lots of edge
          # cases or user un-expectations.
          if PDK::Util::Git.work_tree?(uri.shell_path)
            PDK.logger.warn "Repository '%{repo}' has a work-tree; skipping git reset." % {
              repo: uri.shell_path,
            }
            @path = uri.shell_path
            @temporary = false
            @metadata['template-ref'] = describe_path_and_ref(@path)
            return
          end

          # This is either a bare local repo or a remote. either way it needs cloning.
          # A "remote" can also be git repo on the local filsystem.
          # @todo When switching this over to using rugged, cache the cloned
          # template repo in `%AppData%` or `$XDG_CACHE_DIR` and update before
          # use.
          require 'pdk/util'
          require 'pdk/util/git'

          temp_dir = PDK::Util.make_tmpdir_name('pdk-templates')
          @temporary = true
          origin_repo = uri.bare_uri
          git_ref = uri.uri_fragment

          # Clone the repository
          clone_result = PDK::Util::Git.git('clone', origin_repo, temp_dir)
          unless clone_result[:exit_code].zero?
            PDK.logger.error clone_result[:stdout]
            PDK.logger.error clone_result[:stderr]
            raise PDK::CLI::FatalError, "Unable to clone git repository at '%{repo}' into '%{dest}'." % { repo: origin_repo, dest: temp_dir }
          end
          @path = PDK::Util.canonical_path(temp_dir)

          # Checkout the git reference
          if PDK::Util::Git.work_dir_clean?(temp_dir)
            Dir.chdir(temp_dir) do
              full_ref = PDK::Util::Git.ls_remote(temp_dir, git_ref)
              @metadata['template-ref'] = describe_path_and_ref(temp_dir, full_ref)
              reset_result = PDK::Util::Git.git('reset', '--hard', full_ref)
              return if reset_result[:exit_code].zero?

              PDK.logger.error reset_result[:stdout]
              PDK.logger.error reset_result[:stderr]
              raise PDK::CLI::FatalError, "Unable to checkout '%{ref}' of git repository at '%{path}'." % { ref: git_ref, path: temp_dir }
            end
          else
            PDK.logger.warn "Uncommitted changes found when attempting to checkout '%{ref}' of git repository at '%{path}'; skipping git reset." % { ref: git_ref, path: temp_dir }
            @metadata['template-ref'] = describe_path_and_ref(temp_dir)
          end
        end

        private

        #:nocov: This is a just a wrapper for another method
        def describe_path_and_ref(path, ref = nil)
          require 'pdk/util/git'
          PDK::Util::Git.describe(File.join(path, '.git'), ref)
        end
        #:nocov:
      end
    end
  end
end
