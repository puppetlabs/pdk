require 'pdk'

module PDK
  module Util
    module Version
      def self.version_string
        require 'pdk/version'

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
        require 'pdk/util/git'
        source_git_dir = File.join(File.expand_path('../../..', File.dirname(__FILE__)), '.git')

        return unless File.directory?(source_git_dir)

        PDK::Util::Git.describe(source_git_dir)
      end

      def self.version_file
        require 'pdk/util'

        # FIXME: this gets called a LOT and doesn't currently get cached
        PDK::Util.find_upwards('PDK_VERSION', File.dirname(__FILE__))
      end
    end
  end
end
