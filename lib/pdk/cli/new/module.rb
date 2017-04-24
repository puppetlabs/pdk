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
            usage _("module [options] <module_name> [target_dir]")
            summary _("Create a new module named <module_name> using given options")

            option nil, 'template-url', _("Overrides the template to use for this module."), argument: :required

            option nil, 'license', _("Specifies the license this module is written under. This should be a identifier from https://spdx.org/licenses/. Common values are 'Apache-2.0', 'MIT', or 'proprietary'."), argument: :required

            option nil, 'vcs', _("Specifies the version control driver. Valid values: 'git', 'none'. Default: 'git'."), argument: :required

            flag nil, 'skip-interview', _("When specified, skips interactive querying of metadata.")

            run do |opts, args, cmd|
              module_name = args.shift
              target_dir = args.shift

              unless OptionValidator.is_valid_module_name?(module_name)
                PDK.logger.error(_("'%{module_name}' is not a valid module name.") % {:module_name => module_name})
                PDK.logger.error(_("Module names must begin with a lowercase letter and can only include lowercase letters, digits, and underscores"))
                exit 1
              end

              puts _("Creating new module: %{modname}") % {:modname => module_name}
              PDK::Generate::Module.invoke(module_name, opts)
            end
          end
        end
      end
    end
  end
end
