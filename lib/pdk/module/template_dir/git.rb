require 'pdk'
require 'pdk/module/template_dir/base'

module PDK
  module Module
    module TemplateDir
      class Git < Base
        def template_path(uri)
          # We don't do a checkout of local-path repos. There are lots of edge
          # cases or user un-expectations.
          if PDK::Util::Git.work_tree?(uri.shell_path)
            PDK.logger.warn _("Repository '%{repo}' has a work-tree; skipping git reset.") % {
              repo: uri.shell_path,
            }
            [uri.shell_path, false]
          else
            # This is either a bare local repo or a remote. either way it needs cloning.
            # A "remote" can also be git repo on the local filsystem.
            [clone_template_repo(uri), true]
          end
        end

        # For git repositories, this will return the URL to the repository and
        # a reference to the HEAD.
        #
        # @return [Hash{String => String}] A hash of identifying metadata.
        def metadata
          super.merge('template-url' => uri.metadata_format, 'template-ref' => cache_template_ref(@path))
        end

        private

        def cache_template_ref(path, ref = nil)
          require 'pdk/util/git'

          @template_ref ||= PDK::Util::Git.describe(File.join(path, '.git'), ref)
        end

        # @return [String] Path to working directory into which template repo has been cloned and reset
        #
        # @raise [PDK::CLI::FatalError] If unable to clone the given origin_repo into a tempdir.
        # @raise [PDK::CLI::FatalError] If reset HEAD of the cloned repo to desired ref.
        #
        # @api private
        def clone_template_repo(uri)
          # @todo When switching this over to using rugged, cache the cloned
          # template repo in `%AppData%` or `$XDG_CACHE_DIR` and update before
          # use.
          require 'pdk/util'
          require 'pdk/util/git'

          temp_dir = PDK::Util.make_tmpdir_name('pdk-templates')
          origin_repo = uri.bare_uri
          git_ref = uri.uri_fragment

          clone_result = PDK::Util::Git.git('clone', origin_repo, temp_dir)

          if clone_result[:exit_code].zero?
            checkout_template_ref(temp_dir, git_ref)
          else
            PDK.logger.error clone_result[:stdout]
            PDK.logger.error clone_result[:stderr]
            raise PDK::CLI::FatalError, _("Unable to clone git repository at '%{repo}' into '%{dest}'.") % { repo: origin_repo, dest: temp_dir }
          end

          PDK::Util.canonical_path(temp_dir)
        end

        # @api private
        def checkout_template_ref(path, ref)
          require 'pdk/util/git'

          if PDK::Util::Git.work_dir_clean?(path)
            Dir.chdir(path) do
              full_ref = PDK::Util::Git.ls_remote(path, ref)
              cache_template_ref(path, full_ref)
              reset_result = PDK::Util::Git.git('reset', '--hard', full_ref)
              return if reset_result[:exit_code].zero?

              PDK.logger.error reset_result[:stdout]
              PDK.logger.error reset_result[:stderr]
              raise PDK::CLI::FatalError, _("Unable to checkout '%{ref}' of git repository at '%{path}'.") % { ref: ref, path: path }
            end
          else
            PDK.logger.warn _("Uncommitted changes found when attempting to checkout '%{ref}' of git repository at '%{path}'; skipping git reset.") % { ref: ref, path: path }
          end
        end
      end
    end
  end
end
