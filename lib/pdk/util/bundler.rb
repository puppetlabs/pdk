require 'bundler'
require 'digest'
require 'fileutils'
require 'pdk/util'
require 'pdk/cli/exec'

module PDK
  module Util
    module Bundler
      class BundleHelper; end

      def self.ensure_bundle!(gem_overrides = {})
        bundle = BundleHelper.new

        if already_bundled?(bundle.gemfile, gem_overrides)
          PDK.logger.debug(_('Bundler managed gems already up to date.'))
          return
        end

        unless bundle.gemfile?
          PDK.logger.debug(_("No Gemfile found in '%{cwd}'. Skipping bundler management.") % { cwd: Dir.pwd })
          return
        end

        # Generate initial Gemfile.lock
        if bundle.locked?
          # Update puppet-related gem dependencies by re-resolving them specifically.
          # If this is a packaged install, only consider already available gems at this point.
          bundle.update_lock!(gem_overrides, local: PDK::Util.package_install?)
        else
          bundle.lock!(gem_overrides)
        end

        # Check for any still-unresolved dependencies. For packaged installs, this should
        # only evaluate to false if the user has added custom gems that we don't vendor, in
        # which case `bundle install` will resolve new dependencies as needed.
        unless bundle.installed?(gem_overrides)
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

        def gemfile?
          !gemfile.nil?
        end

        def locked?
          !gemfile_lock.nil?
        end

        def installed?(gem_overrides = {})
          PDK.logger.debug(_('Checking for missing Gemfile dependencies.'))

          argv = ['check', "--gemfile=#{gemfile}"]
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

        def lock!(gem_overrides = {})
          if PDK::Util.package_install?
            # In packaged installs, use vendored Gemfile.lock as a starting point.
            # Subsequent 'bundle install' will still pick up any new dependencies.
            vendored_gemfile_lock = File.join(PDK::Util.package_cachedir, 'Gemfile.lock')

            unless File.exist?(vendored_gemfile_lock)
              raise PDK::CLI::FatalError, _('Vendored Gemfile.lock (%{source}) not found.') % {
                source: vendored_gemfile_lock,
              }
            end

            PDK.logger.debug(_('Using vendored Gemfile.lock from %{source}.') % { source: vendored_gemfile_lock })
            FileUtils.cp(vendored_gemfile_lock, File.join(PDK::Util.module_root, 'Gemfile.lock'))

            # Update the vendored lock with any overrides
            update_lock!(gem_overrides, local: true) unless gem_overrides.empty?
          else
            argv = ['lock']

            cmd = bundle_command(*argv).tap do |c|
              c.add_spinner(_('Resolving Gemfile dependencies.'))
              c.update_environment(gemfile_env(gem_overrides)) unless gem_overrides.empty?
            end

            result = cmd.execute!

            unless result[:exit_code].zero?
              PDK.logger.fatal(result.values_at(:stdout, :stderr).join("\n"))
              raise PDK::CLI::FatalError, _('Unable to resolve Gemfile dependencies.')
            end
          end

          # After initial lockfile generation, re-resolve json gem to built-in
          # version to avoid unncessary native compilation attempts.
          update_lock!({ json: nil }, local: true)

          true
        end

        def update_lock!(gem_overrides, options = {})
          return true if gem_overrides.empty?

          PDK.logger.debug(_('Updating Gemfile dependencies.'))

          update_gems = gem_overrides.keys.join(' ')

          argv = ['lock', "--update=#{update_gems}"]
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

        def gemfile_lock
          @gemfile_lock ||= PDK::Util.find_upwards('Gemfile.lock')
        end

        def bundle_cachedir
          @bundle_cachedir ||= PDK::Util.package_install? ? PDK::Util.package_cachedir : File.join(PDK::Util.cachedir)
        end

        def gemfile_env(gem_overrides)
          gemfile_env = {}

          return gemfile_env unless gem_overrides.respond_to?(:each)

          gem_overrides.each do |gem, version|
            gemfile_env['PUPPET_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'puppet'
            gemfile_env['FACTER_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'facter'
            gemfile_env['HIERA_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'hiera'
          end

          gemfile_env
        end
      end
    end
  end
end
