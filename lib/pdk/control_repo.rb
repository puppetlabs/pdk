require 'pdk'

module PDK
  module ControlRepo
    CONTROL_REPO_FILES = %w[environment.conf Puppetfile].freeze

    # Returns path to the root of the Control Repo being worked on.
    #
    # An environment.conf is required for a PDK compatible Control Repo,
    # whereas Puppetfile is optional.
    #
    # Note - A Bolt Project can also be a Control Repo.
    #
    # Note - Non-Directory environments can exist however directory based
    # environments are the supported/preferred way.
    #
    # @see https://puppet.com/docs/pe/latest/control_repo.html
    #
    # @param strict_check [Boolean] When strict_check is true, only return the path
    #   if the Control Repo is strictly _only_ a control repository. For example,
    #   not also a Puppet Bolt project directory  Default is false.
    #
    # @return [String, nil] Fully qualified base path to Control Repo, or nil if
    #   the current working dir does not appear to be within a Control Repo.
    def find_control_repo_root(strict_check = false)
      environment_conf_path = PDK::Util.find_upwards('environment.conf')
      path = if environment_conf_path
               File.dirname(environment_conf_path)
             elsif control_repo_root?(Dir.pwd)
               Dir.pwd
             else
               nil
             end
      return path if path.nil? || !strict_check
      PDK::Bolt.bolt_project_root?(path) ? nil : path
    end
    module_function :find_control_repo_root

    # Returns true or false depending on if any of the common files in a Control Repo
    # are found in the specified directory. If a directory is not specified, the current
    # working directory is used.
    #
    # @return [boolean] True if any folders from CONTROL_REPO_FILES are found in the current dir,
    #   false otherwise.
    def control_repo_root?(path = Dir.pwd)
      CONTROL_REPO_FILES.any? { |file| PDK::Util::Filesystem.file?(File.join(path, file)) }
    end
    module_function :control_repo_root?
  end
end
