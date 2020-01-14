require 'pdk'

module PDK
  module Bolt
    # Returns true or false depending on if any of the common files and directories in
    # a Bolt Project are found in the specified directory. If a directory is not specified,
    # the current working directory is used.
    #
    # @see https://puppet.com/docs/bolt/latest/bolt_project_directories.html
    #
    # @return [boolean] True if any bolt specific files or directories are present
    #
    def bolt_project_root?(path = Dir.pwd)
      return true if File.basename(path) == 'Boltdir' && PDK::Util::Filesystem.directory?(path)
      PDK::Util::Filesystem.file?(File.join(path, 'bolt.yaml'))
    end
    module_function :bolt_project_root?
  end
end
