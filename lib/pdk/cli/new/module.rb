require 'cri'
require 'pdk/cli/util/option_validator'

require 'pdk/generators/module'

module PDK
  module CLI
    module New
      class Module
        include PDK::CLI::Util

        def self.command
          @module ||= Cri::Command.define do
            name 'module'
            usage 'module [options] <module_name> [target_dir]'
            summary 'Create a new module named <module_name> using given options'

            option nil, 'template-url', 'Overrides the template to use for this module.', argument: :required

            option nil, 'license', 'Specifies the license this module is written under. This should be a identifier from https://spdx.org/licenses/. Common values are "Apache-2.0", "MIT", or "proprietary".', argument: :required

            option nil, 'vcs', 'Specifies the version control driver. Valid values: git, none. Default: git.', argument: :required

            run do |opts, args, cmd|
              puts "Creating new module: #{args[0]}"
              PDK::Generate::Module.invoke(args[0], opts)
            end
          end
        end
      end
    end
  end
end
