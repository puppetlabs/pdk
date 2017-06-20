require 'bundler'
require 'tty-spinner'
require 'pdk/util'
require 'pdk/cli/exec'

module PDK
  module Util
    module Bundler
      class BundleHelper; end

      def self.ensure_bundle!
        bundle = BundleHelper.new

        if already_bundled?(bundle.gemfile)
          PDK.logger.debug(_('Bundle has already been installed, skipping run'))
          return
        end

        unless bundle.gemfile?
          PDK.logger.debug(_("No Gemfile found in '%{cwd}', skipping bundler management") % { cwd: Dir.pwd })
          return
        end

        unless bundle.locked?
          unless bundle.lock!
            raise PDK::CLI::FatalError, _('Unable to resolve Gemfile dependencies.')
          end
        end

        unless bundle.installed?
          unless bundle.install!
            raise PDK::CLI::FatalError, _('Unable to install missing Gemfile dependencies.')
          end
        end

        mark_as_bundled!(bundle.gemfile)
      end

      def self.already_bundled?(gemfile)
        !(@bundled ||= {})[gemfile].nil?
      end

      def self.mark_as_bundled!(gemfile)
        (@bundled ||= {})[gemfile] = true
      end

      def self.ensure_binstubs!(*gems)
        bundle = BundleHelper.new

        unless bundle.binstubs!(gems) # rubocop:disable Style/GuardClause
          raise PDK::CLI::FatalError, _('Unable to install requested binstubs.')
        end
      end

      class BundleHelper
        def gemfile?
          !gemfile.nil?
        end

        def locked?
          !gemfile_lock.nil?
        end

        def installed?
          output_start(_('Checking for missing Gemfile dependencies'))

          result = invoke('check', "--gemfile=#{gemfile}", "--path=#{bundle_cachedir}")

          output_end(:success)

          result[:exit_code].zero?
        end

        def lock!
          output_start(_('Resolving Gemfile dependencies'))

          result = invoke('lock')

          if result[:exit_code].zero?
            output_end(:success)
          else
            output_end(:failure)
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        def install!
          output_start(_('Installing missing Gemfile dependencies'))

          result = invoke('install', "--gemfile=#{gemfile}", "--path=#{bundle_cachedir}")

          if result[:exit_code].zero?
            output_end(:success)
          else
            output_end(:failure)
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        def binstubs!(gems)
          # FIXME: wrap in progress indicator
          result = invoke('binstubs', gems.join(' '), '--force')

          unless result[:exit_code].zero?
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        def gemfile
          @gemfile ||= PDK::Util.find_upwards('Gemfile')
        end

        private

        def invoke(*args)
          bundle_bin = PDK::CLI::Exec.bundle_bin
          command = PDK::CLI::Exec::Command.new(bundle_bin, *args).tap do |c|
            c.context = :module
          end

          command.execute!
        end

        def gemfile_lock
          @gemfile_lock ||= PDK::Util.find_upwards('Gemfile.lock')
        end

        def bundle_cachedir
          @bundle_cachedir ||= File.join(PDK::Util.cachedir, 'bundler')
        end

        # These two output_* methods are just a way to not try to do the spinner stuff on Windows for now.
        def output_start(message)
          if Gem.win_platform?
            $stderr.print "#{message}... "
          else
            @spinner = TTY::Spinner.new("[:spinner] #{message}")
            @spinner.auto_spin
          end
        end

        def output_end(state)
          if Gem.win_platform?
            $stderr.print((state == :success) ? _("done.\n") : _("FAILURE!\n"))
          else
            if state == :success
              @spinner.success
            else
              @spinner.error
            end

            remove_instance_variable(:@spinner)
          end
        end
      end
    end
  end
end
