require 'pdk/version'
require 'pdk/cli/exec'

module PDK
  module Util
    module Version
      def self.version_string
        "#{PDK::VERSION} #{pdk_ref}".strip.freeze
      end

      def self.pdk_ref
        ref = pkg_sha || git_ref
        ref.nil? ? nil : "(#{ref})"
      end

      def self.pkg_sha
        version_file = File.join(File.expand_path('../../..', File.dirname(__FILE__)), 'VERSION')

        if File.exist? version_file
          ver = File.read(version_file)
          sha = ver.strip.split('.')[-1] unless ver.nil?
        end

        sha
      end

      def self.git_ref
        ref_result = PDK::CLI::Exec.git('--git-dir', File.join(File.expand_path('../../..', File.dirname(__FILE__)), '.git'), 'describe', '--all', '--long')

        ref_result[:stdout].strip if ref_result[:exit_code].zero?
      end
    end
  end
end
