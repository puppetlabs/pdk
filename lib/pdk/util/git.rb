module PDK
  module Util
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
        git_bin = Gem.win_platform? ? 'git.exe' : 'git'
        vendored_bin_path = File.join(git_bindir, git_bin)

        PDK::CLI::Exec.try_vendored_bin(vendored_bin_path, git_bin)
      end

      def self.git(*args)
        PDK::CLI::Exec.ensure_bin_present!(git_bin, 'git')

        PDK::CLI::Exec.execute(git_bin, *args)
      end

      def self.repo_exists?(repo, ref = nil)
        args = ['ls-remote', '--exit-code', repo, ref].compact

        git(*args)[:exit_code].zero?
      end
    end
  end
end
