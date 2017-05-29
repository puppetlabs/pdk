require 'cri'
require 'pdk/cli/util/option_validator'

require 'pdk/generators/module'
require 'pdk/generators/puppet_class'

module PDK
  module CLI
    module New
      class PuppetClass
        include PDK::CLI::Util

        def self.command
          @puppet_class ||= Cri::Command.define do
            name 'class'
            usage _("class [options] <class_name> [parameter[:type]] [parameter[:type]] ...")
            summary _("Create a new class named <class_name> using given options")

            option nil, 'template-url', _("Specifies the URL to the template to use when creating the module. Defaults to the template used to create the module, otherwise %{default}") % {:default => PDK::Generate::Module::DEFAULT_TEMPLATE}, argument: :required

            run do |opts, args, cmd|
              class_name = args[0]
              module_dir = Dir.pwd

              if class_name.nil? || class_name.empty?
                puts command.help
                exit 1
              end

              unless PDK::CLI::Util::OptionValidator.is_valid_class_name?(class_name)
                raise PDK::CLI::FatalError, _("'%{name}' is not a valid class name") % {name: class_name}
              end

              if args.length > 1
                opts[:params] = args[1..-1].map { |r| PDK::CLI::Util::OptionNormalizer.parameter_specification(r) }
              end

              PDK::Generate::PuppetClass.new(module_dir, class_name, opts).run
            end
          end
        end
      end
    end
  end
end
