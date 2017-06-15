require 'bundler'
require 'pdk/logger'
require 'pdk/util'
require 'pdk/cli/exec'

module PDK
  module Util
    module Bundler
      class BundleHelper; end

      def self.ensure_bundle!
        bundle = BundleHelper.new

        unless bundle.gemfile?
          PDK.logger.debug(_("No Gemfile found in '%{cwd}', skipping bundler management") % { cwd: Dir.pwd })
          return
        end

        unless bundle.locked?
          unless bundle.lock!
            raise PDK::CLI::FatalError, _('Unable to resolve Gemfile dependencies.')
          end
        end

        unless bundle.installed? # rubocop:disable Style/GuardClause
          unless bundle.install!
            raise PDK::CLI::FatalError, _('Unable to install missing Gemfile dependencies.')
          end
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
          PDK.logger.spinner_output_start(_("Checking for missing Gemfile dependencies"))

          result = invoke('check', "--gemfile=#{gemfile}", "--path=#{bundle_cachedir}")

          PDK.logger.spinner_output_end(:success)

          result[:exit_code].zero?
        end

        def lock!
          PDK.logger.spinner_output_start(_("Resolving Gemfile dependencies"))

          result = invoke('lock')

          if result[:exit_code].zero?
            PDK.logger.spinner_output_end(:success)
          else
            PDK.logger.spinner_output_end(:failure)
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        def install!
          PDK.logger.spinner_output_start(_("Installing missing Gemfile dependencies"))

          result = invoke('install', "--gemfile=#{gemfile}", "--path=#{bundle_cachedir}")

          if result[:exit_code].zero?
            PDK.logger.spinner_output_end(:success)
          else
            PDK.logger.spinner_output_end(:failure)
            $stderr.puts result[:stdout]
            $stderr.puts result[:stderr]
          end

          result[:exit_code].zero?
        end

        private

        def invoke(*args)
          ::Bundler.with_clean_env do
            PDK::CLI::Exec.bundle(*args)
          end
        end

        def gemfile
          @gemfile ||= PDK::Util.find_upwards('Gemfile')
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
