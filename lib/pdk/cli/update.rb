# frozen_string_literal: true

require 'pdk/cli/util'
require 'pdk/util'

module PDK::CLI
  @update_cmd = @base_cmd.define_command do
    name 'update'
    usage _('update [options]')
    summary _('Update a module that has been created by or converted for use by PDK.')

    flag nil, :noop, _('Do not update the module, just output what would be done.')
    flag nil, :force, _('Update the module automatically, with no prompts.')

    run do |opts, _args, _cmd|
      require 'pdk/module/update'

      PDK::CLI::Util.ensure_in_module!(
        message:   _('`pdk update` can only be run from inside a valid module directory.'),
        log_level: :info,
      )

      raise PDK::CLI::ExitWithError, _('This module does not appear to be PDK compatible. To make the module compatible with PDK, run `pdk convert`.') unless PDK::Util.module_pdk_compatible?

      if opts[:noop] && opts[:force]
        raise PDK::CLI::ExitWithError, _('You can not specify --noop and --force when updating a module')
      end

      updater = PDK::Module::Update.new(opts)

      updater.run
    end
  end
end
