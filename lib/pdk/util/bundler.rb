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
          command = bundle_command('check', "--gemfile=#{gemfile}", "--path=#{bundle_cachedir}").tap do |c|
            c.add_spinner(_('Checking for missing Gemfile dependencies'))
          end

          result = command.execute!

          unless result[:exit_code].zero?
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        def lock!
          command = bundle_command('lock').tap do |c|
            c.add_spinner(_('Resolving Gemfile dependencies'))
          end

          result = command.execute!

          unless result[:exit_code].zero?
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        def install!
          command = bundle_command('install', "--gemfile=#{gemfile}", "--path=#{bundle_cachedir}").tap do |c|
            c.add_spinner(_('Installing missing Gemfile dependencies'))
          end

          result = command.execute!

          unless result[:exit_code].zero?
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        def binstubs!(gems)
          binstub_dir = File.join(File.dirname(gemfile), 'bin')
          return true if gems.all? { |gem| File.file?(File.join(binstub_dir, gem)) }

          command = bundle_command('binstubs', gems.join(' '), '--force')

          result = command.execute!

          unless result[:exit_code].zero?
            PDK.logger.error(_('Failed to generate binstubs for %{gems}') % { gems: gems.join(' ') })
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        def gemfile
          @gemfile ||= PDK::Util.find_upwards('Gemfile')
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
          @bundle_cachedir ||= File.join(PDK::Util.cachedir, 'bundler')
        end
      end
    end
  end
end
