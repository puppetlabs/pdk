require 'pdk'

module PDK
  module Util
    class GitError < StandardError
      attr_reader :stdout
      attr_reader :stderr
      attr_reader :exit_code
      attr_reader :args

      def initialze(args, result)
        @args = args
        @stdout = result[:stdout]
        @stderr = result[:stderr]
        @exit_code = result[:exit_code]

        super('Git command failed: git %{args}' % { args: args.join(' ') })
      end
    end

    module Git
      GIT_QUERY_CACHE_TTL ||= 10

      def self.git_bindir
        @git_dir ||= File.join('private', 'git', Gem.win_platform? ? 'cmd' : 'bin')
      end

      def self.git_paths
        @paths ||= begin
          paths = [File.join(PDK::Util.pdk_package_basedir, git_bindir)]

          if Gem.win_platform?
            paths << File.join(PDK::Util.pdk_package_basedir, 'private', 'git', 'mingw64', 'bin')
            paths << File.join(PDK::Util.pdk_package_basedir, 'private', 'git', 'mingw64', 'libexec', 'git-core')
            paths << File.join(PDK::Util.pdk_package_basedir, 'private', 'git', 'usr', 'bin')
          end

          paths
        end
      end

      def self.git_bin
        require 'pdk/cli/exec'

        git_bin = Gem.win_platform? ? 'git.exe' : 'git'
        vendored_bin_path = File.join(git_bindir, git_bin)

        PDK::CLI::Exec.try_vendored_bin(vendored_bin_path, git_bin)
      end

      def self.git(*args)
        require 'pdk/cli/exec'

        PDK::CLI::Exec.ensure_bin_present!(git_bin, 'git')

        PDK::CLI::Exec.execute(git_bin, *args)
      end

      def self.git_with_env(env, *args)
        require 'pdk/cli/exec'

        PDK::CLI::Exec.ensure_bin_present!(git_bin, 'git')

        PDK::CLI::Exec.execute_with_env(env, git_bin, *args)
      end

      def self.repo?(maybe_repo)
        result = cached_git_query(maybe_repo, :repo?)
        return result unless result.nil?
        result = if PDK::Util::Filesystem.directory?(maybe_repo)
                   # Use boolean shortcircuiting here. The mostly likely type of git repo
                   # is a "normal" repo with a working tree. Bare repos do not have work tree
                   work_tree?(maybe_repo) || bare_repo?(maybe_repo)
                 else
                   remote_repo?(maybe_repo)
                 end
        cache_query_result(maybe_repo, :repo?, result)
      end

      def self.bare_repo?(maybe_repo)
        env = { 'GIT_DIR' => maybe_repo }
        rev_parse = git_with_env(env, 'rev-parse', '--is-bare-repository')

        rev_parse[:exit_code].zero? && rev_parse[:stdout].strip == 'true'
      end

      def self.remote_repo?(maybe_repo)
        git('ls-remote', '--exit-code', maybe_repo)[:exit_code].zero?
      end

      def self.work_tree?(path)
        return false unless PDK::Util::Filesystem.directory?(path)
        result = cached_git_query(path, :work_tree?)
        return result unless result.nil?

        Dir.chdir(path) do
          rev_parse = git('rev-parse', '--is-inside-work-tree')
          cache_query_result(path, :work_tree?, rev_parse[:exit_code].zero? && rev_parse[:stdout].strip == 'true')
        end
      end

      def self.work_dir_clean?(repo)
        raise PDK::CLI::ExitWithError, 'Unable to locate git work dir "%{workdir}"' % { workdir: repo } unless PDK::Util::Filesystem.directory?(repo)
        raise PDK::CLI::ExitWithError, 'Unable to locate git dir "%{gitdir}"' % { gitdir: repo } unless PDK::Util::Filesystem.directory?(File.join(repo, '.git'))

        git('--work-tree', repo, '--git-dir', File.join(repo, '.git'), 'status', '--untracked-files=no', '--porcelain', repo)[:stdout].empty?
      end

      def self.ls_remote(repo, ref)
        if PDK::Util::Filesystem.directory?(repo)
          repo = 'file://' + repo
        end

        output = git('ls-remote', '--refs', repo, ref)

        unless output[:exit_code].zero?
          PDK.logger.error output[:stdout]
          PDK.logger.error output[:stderr]
          raise PDK::CLI::ExitWithError, 'Unable to access the template repository "%{repository}"' % {
            repository: repo,
          }
        end

        matching_refs = output[:stdout].split(%r{\r?\n}).map { |r| r.split("\t") }
        matching_ref = matching_refs.find { |_sha, remote_ref| remote_ref == "refs/tags/#{ref}" || remote_ref == "refs/remotes/origin/#{ref}" || remote_ref == "refs/heads/#{ref}" }
        raise PDK::CLI::ExitWithError, 'Unable to find a branch or tag named "%{ref}" in %{repo}' % { ref: ref, repo: repo } if matching_ref.nil?
        matching_ref.first
      end

      def self.describe(path, ref = nil)
        args = ['--git-dir', path, 'describe', '--all', '--long', '--always', ref].compact
        result = git(*args)
        raise PDK::Util::GitError, args, result unless result[:exit_code].zero?
        result[:stdout].strip
      end

      def self.tag?(git_remote, tag_name)
        git('ls-remote', '--tags', '--exit-code', git_remote, tag_name)[:exit_code].zero?
      end

      # Clears any cached information for git queries
      # Should only be used during testing
      # @api private
      def self.clear_cached_information
        @git_repo_expire_cache = nil
        @git_repo_cache = nil
      end

      def self.cached_git_query(repo, query)
        # TODO: Not thread safe
        if @git_repo_expire_cache.nil?
          @git_repo_expire_cache = Time.now + GIT_QUERY_CACHE_TTL # Expire the cache every GIT_QUERY_CACHE_TTL seconds
          @git_repo_cache = {}
        elsif Time.now > @git_repo_expire_cache
          @git_repo_expire_cache = Time.now + GIT_QUERY_CACHE_TTL
          @git_repo_cache = {}
        end
        return nil if @git_repo_cache[repo].nil?
        @git_repo_cache[repo][query]
      end
      private_class_method :cached_git_query

      def self.cache_query_result(repo, query, result)
        # TODO: Not thread safe?
        if @git_repo_expire_cache.nil?
          @git_repo_expire_cache = Time.now + GIT_QUERY_CACHE_TTL
          @git_repo_cache = {}
        end
        if @git_repo_cache[repo].nil?
          @git_repo_cache[repo] = { query => result }
        else
          @git_repo_cache[repo][query] = result
        end
        result
      end
      private_class_method :cache_query_result
    end
  end
end
