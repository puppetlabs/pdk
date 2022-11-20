require 'pdk'

module PDK
  module Util
    module Bundler
      class BundleHelper; end

      def self.ensure_bundle!(gem_overrides = nil)
        bundle = BundleHelper.new

        # This will default ensure_bundle! to re-resolving everything to latest
        gem_overrides ||= { puppet: nil, hiera: nil, facter: nil }

        if already_bundled?(bundle.gemfile, gem_overrides)
          PDK.logger.debug('Bundler managed gems already up to date.')
          return
        end

        unless bundle.gemfile?
          PDK.logger.debug("No Gemfile found in '%{cwd}'. Skipping bundler management." % { cwd: Dir.pwd })
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

          PDK::Util::Filesystem.mv(original_lockfile, temp_lockfile)

          all_deps_available = bundle.installed?(gem_overrides)
        ensure
          PDK::Util::Filesystem.mv(temp_lockfile, original_lockfile, force: true)
        end

        bundle.update_lock!(with: gem_overrides, local: all_deps_available)

        # If there are missing dependencies after updating the lockfile, let `bundle install`
        # go out and get them. If the specified puppet gem version points to a remote location
        # or local filepath, then run bundle install as well.
        if !bundle.installed?(gem_overrides) || (gem_overrides[:puppet] && gem_overrides[:puppet].start_with?('file://', 'git://', 'https://'))
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
        require 'digest'

        override_sig = (gem_overrides || {}).sort_by { |gem, _| gem.to_s }.to_s
        Digest::MD5.hexdigest(gemfile.to_s + override_sig)
      end
      private_class_method :bundle_cache_key

      class BundleHelper
        def gemfile
          require 'pdk/util'
          @gemfile ||= PDK::Util.find_upwards('Gemfile')
        end

        def gemfile_lock
          return if gemfile.nil?
          @gemfile_lock ||= File.join(File.dirname(gemfile), 'Gemfile.lock')
        end

        def gemfile?
          !gemfile.nil?
        end

        def locked?
          !gemfile_lock.nil? && PDK::Util::Filesystem.file?(gemfile_lock)
        end

        def installed?(gem_overrides = {})
          PDK.logger.debug('Checking for missing Gemfile dependencies.')

          argv = ['check', "--gemfile=#{gemfile}", '--dry-run']

          cmd = bundle_command(*argv).tap do |c|
            c.update_environment(gemfile_env(gem_overrides)) unless gem_overrides.empty?
          end

          result = cmd.execute!

          result[:exit_code].zero?
        end

        def lock!
          require 'pdk/util'
          require 'pdk/util/ruby_version'

          if PDK::Util.package_install?
            # In packaged installs, use vendored Gemfile.lock as a starting point.
            # Subsequent 'bundle install' will still pick up any new dependencies.
            vendored_lockfiles = [
              File.join(PDK::Util.package_cachedir, "Gemfile-#{PDK::Util::RubyVersion.active_ruby_version}.lock"),
              File.join(PDK::Util.package_cachedir, 'Gemfile.lock'),
            ]

            vendored_gemfile_lock = vendored_lockfiles.find do |lockfile|
              PDK::Util::Filesystem.exist?(lockfile)
            end

            unless vendored_gemfile_lock
              raise PDK::CLI::FatalError, 'Vendored Gemfile.lock (%{source}) not found.' % {
                source: vendored_gemfile_lock,
              }
            end

            PDK.logger.debug('Using vendored Gemfile.lock from %{source}.' % { source: vendored_gemfile_lock })
            PDK::Util::Filesystem.cp(vendored_gemfile_lock, File.join(PDK::Util.module_root, 'Gemfile.lock'))
          else
            argv = ['lock']

            cmd = bundle_command(*argv).tap do |c|
              c.add_spinner('Resolving default Gemfile dependencies.')
            end

            result = cmd.execute!

            unless result[:exit_code].zero?
              PDK.logger.fatal(result.values_at(:stdout, :stderr).join("\n")) unless PDK.logger.debug?
              raise PDK::CLI::FatalError, 'Unable to resolve default Gemfile dependencies.'
            end

            # After initial lockfile generation, re-resolve json gem to built-in
            # version to avoid unncessary native compilation attempts. For packaged
            # installs this is done during the generation of the vendored Gemfile.lock
            update_lock!(only: { json: nil }, local: true)
          end

          true
        end

        def update_lock!(options = {})
          PDK.logger.debug('Updating Gemfile dependencies.')

          argv = ['lock', "--lockfile=#{gemfile_lock}", '--update']

          overrides = nil

          if options && options[:only]
            update_gems = options[:only].keys.map(&:to_s)
            argv << update_gems
            argv.flatten!

            overrides = options[:only]
          elsif options && options[:with]
            overrides = options[:with]
          end

          argv << '--local' if options && options[:local]
          argv << '--conservative' if options && options[:conservative]

          cmd = bundle_command(*argv).tap do |c|
            c.update_environment('BUNDLE_GEMFILE' => gemfile)
            c.update_environment(gemfile_env(overrides)) if overrides
          end

          result = cmd.execute!

          unless result[:exit_code].zero?
            PDK.logger.fatal(result.values_at(:stdout, :stderr).join("\n")) unless PDK.logger.debug?
            raise PDK::CLI::FatalError, 'Unable to resolve Gemfile dependencies.'
          end

          true
        end

        def install!(gem_overrides = {})
          require 'pdk/util/ruby_version'

          argv = ['install', "--gemfile=#{gemfile}"]
          argv << '-j4' unless Gem.win_platform? && Gem::Version.new(PDK::Util::RubyVersion.active_ruby_version) < Gem::Version.new('2.3.5')

          cmd = bundle_command(*argv).tap do |c|
            c.add_spinner('Installing missing Gemfile dependencies.')
            c.update_environment(gemfile_env(gem_overrides)) unless gem_overrides.empty?
          end

          result = cmd.execute!

          unless result[:exit_code].zero?
            PDK.logger.fatal(result.values_at(:stdout, :stderr).join("\n")) unless PDK.logger.debug?
            raise PDK::CLI::FatalError, 'Unable to install missing Gemfile dependencies.'
          end

          true
        end

        def binstubs!(gems)
          raise PDK::CLI::FatalError, 'Unable to install requested binstubs as the Gemfile is missing' if gemfile.nil?
          binstub_dir = File.join(File.dirname(gemfile), 'bin')
          return true if gems.all? { |gem| PDK::Util::Filesystem.file?(File.join(binstub_dir, gem)) }

          cmd = bundle_command('binstubs', *gems, '--force')
          result = cmd.execute!

          unless result[:exit_code].zero?
            PDK.logger.fatal("Failed to generate binstubs for '%{gems}':\n%{output}" % { gems: gems.join(' '), output: result.values_at(:stdout, :stderr).join("\n") }) unless PDK.logger.debug?
            raise PDK::CLI::FatalError, 'Unable to install requested binstubs.'
          end

          true
        end

        def self.gemfile_env(gem_overrides)
          gemfile_env = {}

          return gemfile_env unless gem_overrides.respond_to?(:each)

          gem_overrides.each do |gem, version|
            gemfile_env['PUPPET_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'puppet' && !version.nil?
            gemfile_env['FACTER_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'facter' && !version.nil?
            gemfile_env['HIERA_GEM_VERSION'] = version if gem.respond_to?(:to_s) && gem.to_s == 'hiera' && !version.nil?
          end

          gemfile_env
        end

        private

        def gemfile_env(gem_overrides)
          self.class.gemfile_env(gem_overrides)
        end

        def bundle_command(*args)
          require 'pdk/cli/exec'
          require 'pdk/cli/exec/command'

          PDK::CLI::Exec::Command.new(PDK::CLI::Exec.bundle_bin, *args).tap do |c|
            c.context = :module
          end
        end
      end
    end
  end
end
