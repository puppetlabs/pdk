require 'bundler'
require 'childprocess'
require 'English'
require 'tempfile'
require 'tty-which'

require 'pdk/util'
require 'pdk/util/git'
require 'pdk/util/ruby_version'
require 'pdk/cli/util/spinner'

module PDK
  module CLI
    module Exec
      require 'pdk/cli/exec/command'
      require 'pdk/cli/exec/interactive_command'

      def self.execute(*cmd)
        Command.new(*cmd).execute!
      end

      def self.execute_with_env(env, *cmd)
        Command.new(*cmd).tap { |c| c.environment = env }.execute!
      end

      def self.execute_interactive(*cmd)
        InteractiveCommand.new(*cmd).execute!
      end

      def self.execute_interactive_with_env(env, *cmd)
        InteractiveCommand.new(*cmd).tap { |c| c.environment = env }.execute!
      end

      def self.ensure_bin_present!(bin_path, bin_name)
        message = _('Unable to find `%{name}`. Check that it is installed and try again.') % {
          name: bin_name,
        }

        raise PDK::CLI::FatalError, message unless TTY::Which.exist?(bin_path)
      end

      def self.bundle(*args)
        ensure_bin_present!(bundle_bin, 'bundler')

        execute(bundle_bin, *args)
      end

      def self.bundle_bin
        bundle_bin = Gem.win_platform? ? 'bundle.bat' : 'bundle'
        vendored_bin_path = File.join('private', 'ruby', PDK::Util::RubyVersion.active_ruby_version, 'bin', bundle_bin)

        try_vendored_bin(vendored_bin_path, bundle_bin)
      end

      def self.try_vendored_bin(vendored_bin_path, fallback)
        unless PDK::Util.package_install?
          PDK.logger.debug(_("PDK package installation not found. Trying '%{fallback}' from the system PATH instead.") % {
            fallback: fallback,
          })
          return fallback
        end

        vendored_bin_full_path = File.join(PDK::Util.pdk_package_basedir, vendored_bin_path)

        unless File.exist?(vendored_bin_full_path)
          PDK.logger.debug(_("Could not find '%{vendored_bin}' in PDK package. Trying '%{fallback}' from the system PATH instead.") % {
            fallback: fallback,
            vendored_bin: vendored_bin_full_path,
          })
          return fallback
        end

        PDK.logger.debug(_("Using '%{vendored_bin}' from PDK package.") % { vendored_bin: vendored_bin_full_path })
        vendored_bin_full_path
      end
    end
  end
end
