require 'bundler'
require 'digest'
require 'fileutils'
require 'pdk/util'
require 'pdk/cli/exec'

module PDK
  module Util
    module Bundler
      class BundleHelper; end

      def self.ensure_bundle!(gem_overrides = nil)
        bundle = BundleHelper.new

        # This will default ensure_bundle! to re-resolving everything to latest
        gem_overrides ||= { puppet: nil, hiera: nil, facter: nil }

        if already_bundled?(bundle.gemfile, gem_overrides)
          PDK.logger.debug(_('Bundler managed gems already up to date.'))
          return
        end

        unless bundle.gemfile?
          PDK.logger.debug(_("No Gemfile found in '%{cwd}'. Skipping bundler management.") % { cwd: Dir.pwd })
          return
        end

        unless bundle.locked?
          # Generate initial default Gemfile.lock, either from package cache or
          # by invoking `bundle lock`
          bundle.lock!
        end

        # Check if all dependencies will be available once we update the lockfile.
        begin
          original_lockfile = bundle.gemfile_lock
          temp_lockfile = "#{original_lockfile}.tmp"

          FileUtils.mv(original_lockfile, temp_lockfile)

          all_deps_available = bundle.installed?(gem_overrides)
        ensure
          FileUtils.mv(temp_lockfile, original_lockfile, force: true)
        end

        # Update puppet-related gem dependencies by re-resolving them specifically.
        # If there are additional dependencies that aren't available locally, allow
        # `bundle lock` to reach out to rubygems.org
        bundle.update_lock!(gem_overrides, local: all_deps_available)

        # If there were missing dependencies when we checked above, let `bundle install`
        # go out and get them. For packaged installs, this should only be true if the user
        # has added custom gems that we don't vendor.
        unless bundle.installed?
          bundle.install!(gem_overrides)
        end

        mark_as_bundled!(bundle.gemfile, gem_overrides)
      end

      def self.ensure_binstubs!(*gems)
        bundle = BundleHelper.new

        bundle.binstubs!(gems)
      end

      def self.already_bundled?(gemfile, gem_overrides)
        !(@bundled ||= {})[bundle_cache_key(gemfile, gem_overrides)].nil?
      end

      def self.mark_as_bundled!(gemfile, gem_overrides)
        (@bundled ||= {})[bundle_cache_key(gemfile, gem_overrides)] = true
      end

      def self.bundle_cache_key(gemfile, gem_overrides)
        override_sig = (gem_overrides || {}).sort_by { |gem, _| gem.to_s }.to_s
        Digest::MD5.hexdigest(gemfile.to_s + override_sig)
      end
      private_class_method :bundle_cache_key

      class BundleHelper
        def gemfile
          @gemfile ||= PDK::Util.find_upwards('Gemfile')
        end

        def gemfile_lock
          return nil if gemfile.nil?
          @gemfile_lock ||= File.join(File.dirname(gemfile), 'Gemfile.lock')
        end

        def gemfile?
          !gemfile.nil?
        end

        def locked?
          !gemfile_lock.nil? && File.file?(gemfile_lock)
        end

        def installed?(gem_overrides = {})
          PDK.logger.debug(_('Checking for missing Gemfile dependencies.'))

          argv = ['check', "--gemfile=#{gemfile}", '--dry-run']
          argv << "--path=#{bundle_cachedir}" unless PDK::Util.package_install?

          cmd = bundle_command(*argv).tap do |c|
            c.update_environment(gemfile_env(gem_overrides)) unless gem_overrides.empty?
          end

          result = cmd.execute!

          unless result[:exit_code].zero?
            PDK.logger.debug(result.values_at(:stdout, :stderr).join("\n"))
          end

          result[:exit_code].zero?
        end

        def lock!
          if PDK::Util.package_install?
            # In packaged installs, use vendored Gemfile.lock as a starting point.
            # Subsequent 'bundle install' will still pick up any new dependencies.
            vendored_lockfiles = [
              File.join(PDK::Util.package_cachedir, "Gemfile-#{PDK::Util::RubyVersion.active_ruby_version}.lock"),
              File.join(PDK::Util.package_cachedir, 'Gemfile.lock'),
            ]

            vendored_gemfile_lock = vendored_lockfiles.find { |lockfile| File.exist?(lockfile) }

            unless vendored_gemfile_lock
              raise PDK::CLI::FatalError, _('Vendored Gemfile.lock (%{source}) not found.') % {
                source: vendored_gemfile_lock,
              }
            end

            PDK.logger.debug(_('Using vendored Gemfile.lock from %{source}.') % { source: vendored_gemfile_lock })
            FileUtils.cp(vendored_gemfile_lock, File.join(PDK::Util.module_root, 'Gemfile.lock'))
          else
            argv = ['lock']

            cmd = bundle_command(*argv).tap do |c|
              c.add_spinner(_('Resolving default Gemfile dependencies.'))
            end

            result = cmd.execute!

            unless result[:exit_code].zero?
              PDK.logger.fatal(result.values_at(:stdout, :stderr).join("\n"))
              raise PDK::CLI::FatalError, _('Unable to resolve default Gemfile dependencies.')
            end

            # After initial lockfile generation, re-resolve json gem to built-in
            # version to avoid unncessary native compilation attempts. For packaged
            # installs this is done during the generation of the vendored Gemfile.lock
            update_lock!({ json: nil }, local: true)
          end

          true
        end

        def update_lock!(gem_overrides, options = {})
          return true if gem_overrides.empty?

          PDK.logger.debug(_('Updating Gemfile dependencies.'))

          update_gems = gem_overrides.keys.map(&:to_s)

          argv = ['lock', '--update', update_gems].flatten
          argv << '--local' if options && options[:local]

          cmd = bundle_command(*argv).tap do |c|
            c.update_environment(gemfile_env(gem_overrides))
          end

          result = cmd.execute!

          unless result[:exit_code].zero?
            PDK.logger.fatal(result.values_at(:stdout, :stderr).join("\n"))
            raise PDK::CLI::FatalError, _('Unable to resolve Gemfile dependencies.')
          end

          true
        end

        def install!(gem_overrides = {})
          argv = ['install', "--gemfile=#{gemfile}", '-j4']
          argv << "--path=#{bundle_cachedir}" unless PDK::Util.package_install?

          cmd = bundle_command(*argv).tap do |c|
            c.add_spinner(_('Installing missing Gemfile dependencies.'))
            c.update_environment(gemfile_env(gem_overrides)) unless gem_overrides.empty?
          end

          result = cmd.execute!

          unless result[:exit_code].zero?
            PDK.logger.fatal(result.values_at(:stdout, :stderr).join("\n"))
            raise PDK::CLI::FatalError, _('Unable to install missing Gemfile dependencies.')
          end

          true
        end

        def binstubs!(gems)
          binstub_dir = File.join(File.dirname(gemfile), 'bin')
          return true if gems.all? { |gem| File.file?(File.join(binstub_dir, gem)) }

          cmd = bundle_command('binstubs', *gems, '--force')
          result = cmd.execute!

          unless result[:exit_code].zero?
            PDK.logger.fatal(_("Failed to generate binstubs for '%{gems}':\n%{output}") % { gems: gems.join(' '), output: result.values_at(:stdout, :stderr).join("\n") })
            raise PDK::CLI::FatalError, _('Unable to install requested binstubs.')
          end

          true
        end

        private

        def bundle_command(*args)
          PDK::CLI::Exec::Command.new(PDK::CLI::Exec.bundle_bin, *args).tap do |c|
            c.context = :module
          end
        end

        def bundle_cachedir
          @bundle_cachedir ||= PDK::Util.package_install? ? PDK::Util.package_cachedir : File.join(PDK::Util.cachedir)
        end

        def gemfile_env(gem_overrides)
          gemfile_env = {}

          return gemfile_env unless gem_overrides.respond_to?(:each)

          gem_overrides.each do |gem, version|
            gemfile_env['PUPPET_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'puppet' && !version.nil?
            gemfile_env['FACTER_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'facter' && !version.nil?
            gemfile_env['HIERA_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'hiera' && !version.nil?
          end

          gemfile_env
        end
      end
    end
  end
end
