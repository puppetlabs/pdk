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

        super(_('Git command failed: git %{args}' % { args: args.join(' ') }))
      end
    end

    module Git
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
        return bare_repo?(maybe_repo) if File.directory?(maybe_repo)

        remote_repo?(maybe_repo)
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
        return false unless File.directory?(path)

        Dir.chdir(path) do
          rev_parse = git('rev-parse', '--is-inside-work-tree')
          rev_parse[:exit_code].zero? && rev_parse[:stdout].strip == 'true'
        end
      end

      def self.work_dir_clean?(repo)
        raise PDK::CLI::ExitWithError, _('Unable to locate git work dir "%{workdir}"') % { workdir: repo } unless File.directory?(repo)
        raise PDK::CLI::ExitWithError, _('Unable to locate git dir "%{gitdir}"') % { gitdir: repo } unless File.directory?(File.join(repo, '.git'))

        git('--work-tree', repo, '--git-dir', File.join(repo, '.git'), 'status', '--untracked-files=no', '--porcelain', repo)[:stdout].empty?
      end

      def self.ls_remote(repo, ref)
        if File.directory?(repo)
          repo = 'file://' + repo
        end

        output = git('ls-remote', '--refs', repo, ref)

        unless output[:exit_code].zero?
          PDK.logger.error output[:stdout]
          PDK.logger.error output[:stderr]
          raise PDK::CLI::ExitWithError, _('Unable to access the template repository "%{repository}"') % {
            repository: repo,
          }
        end

        matching_refs = output[:stdout].split("\n").map { |r| r.split("\t") }
        matching_ref = matching_refs.find { |_sha, remote_ref| remote_ref == "refs/tags/#{ref}" || remote_ref == "refs/remotes/origin/#{ref}" || remote_ref == "refs/heads/#{ref}" }
        raise PDK::CLI::ExitWithError, _('Unable to find a branch or tag named "%{ref}" in %{repo}') % { ref: ref, repo: repo } if matching_ref.nil?
        matching_ref.first
      end

      def self.describe(path, ref = nil)
        args = ['--git-dir', path, 'describe', '--all', '--long', '--always', ref].compact
        result = git(*args)
        raise PDK::Util::GitError, args, result unless result[:exit_code].zero?
        result[:stdout].strip
      end
    end
  end
end
