require 'pdk/version'
require 'pdk/cli/exec'
require 'pdk/util/git'
require 'pdk/logger'

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
        source_git_dir = File.join(File.expand_path('../../..', File.dirname(__FILE__)), '.git')

        return nil unless File.directory?(source_git_dir)

        ref_result = PDK::Util::Git.git('--git-dir', source_git_dir, 'describe', '--all', '--long')
        return ref_result[:stdout].strip if ref_result[:exit_code].zero?
      end

      def self.version_file
        # FIXME: this gets called a LOT and doesn't currently get cached
        PDK::Util.find_upwards('PDK_VERSION', File.dirname(__FILE__))
      end
    end
  end
end
