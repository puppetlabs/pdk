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
            usage _('module [options] <module_name> [target_dir]')
            summary _('Create a new module named <module_name> using given options')

            option nil, 'template-url', _('Specifies the URL to the template to use when creating the module. Defaults to %{default}') % { default: PDK::Generate::Module::DEFAULT_TEMPLATE }, argument: :required

            option nil, 'license', _("Specifies the license this module is written under. This should be a identifier from https://spdx.org/licenses/. Common values are 'Apache-2.0', 'MIT', or 'proprietary'."), argument: :required

            option nil, 'vcs', _("Specifies the version control driver. Valid values: 'git', 'none'. Default: 'git'."), argument: :required

            flag nil, 'skip-interview', _('When specified, skips interactive querying of metadata.')

            run do |opts, args, _cmd|
              module_name = args[0]
              target_dir = args[1]

              if module_name.nil? || module_name.empty?
                puts command.help
                exit 1
              end

              unless OptionValidator.is_valid_module_name?(module_name)
                error_msg = _(
                  "'%{module_name}' is not a valid module name.\n" \
                  'Module names must begin with a lowercase letter and can only include lowercase letters, digits, and underscores.'
                ) % { module_name: module_name }
                raise PDK::CLI::FatalError, error_msg
              end

              opts[:name] = module_name
              opts[:target_dir] = target_dir.nil? ? module_name : target_dir
              opts[:vcs] ||= 'git'

              PDK.logger.info(_('Creating new module: %{modname}') % { modname: module_name })
              PDK::Generate::Module.invoke(opts)
            end
          end
        end
      end
    end
  end
end
