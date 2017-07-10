require 'pdk/version'
require 'pdk/cli/exec'

module PDK
  module Util
    module Version
      def self.version_string
        "#{PDK::VERSION} #{pdk_ref}".strip.freeze
      end

      def self.pdk_ref
        ref = "#{pkg_sha} #{git_ref}".strip
        ref.empty? ? nil : "(#{ref})"
      end

      def self.pkg_sha
        if version_file && File.exist?(version_file)
          ver = File.read(version_file)
          sha = ver.strip.split('.')[5] unless ver.nil?
        end

        sha
      end

      def self.git_ref
        ref_result = PDK::CLI::Exec.git('--git-dir', File.join(File.expand_path('../../..', File.dirname(__FILE__)), '.git'), 'describe', '--all', '--long')

        ref_result[:stdout].strip if ref_result[:exit_code].zero?
      end

      def self.version_file
        PDK::Util.find_upwards('PDK_VERSION', File.dirname(__FILE__))
      end
    end
  end
end
