require 'pdk/cli/exec'

module PDK
  VERSION = '0.1.0'.freeze

  def self.version_string
    "#{VERSION} #{pdk_ref}".strip
  end

  def self.pdk_ref
    ref = pkg_sha || git_ref
    "(#{ref})"
  end

  def self.pkg_sha
    version_file = File.join(File.expand_path('../..', File.dirname(__FILE__)), 'VERSION')

    if File.exist? version_file
      ver = File.read(version_file)
      sha = ver.strip.split('.')[-1] unless ver.nil?
    end

    sha
  end

  def self.git_ref
    ref_result = PDK::CLI::Exec.git('--git-dir', File.join(File.expand_path('../..', File.dirname(__FILE__)), '.git'), 'describe', '--all', '--long')

    ref_result[:stdout].strip if ref_result[:exit_code].zero?
  end
end
