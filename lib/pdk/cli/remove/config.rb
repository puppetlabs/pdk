module PDK::CLI
  module Remove
    module Config
      def self.run(opts, args)
        item_name = (args.count > 0) ? args[0] : nil
        item_value = (args.count > 1) ? args[1].strip : nil
        item_value = nil if !item_value.nil? && item_value.empty?

        force = opts[:force] || false

        raise PDK::CLI::ExitWithError, 'Configuration name is required' if item_name.nil?

        current_value = PDK.config.get(item_name)
        raise PDK::CLI::ExitWithError, "The configuration item '%{name}' can not be removed." % { name: item_name } if current_value.is_a?(PDK::Config::Namespace)
        if current_value.nil?
          PDK.logger.info("Could not remove '%{name}' as it has not been set" % { name: item_name })
          return 0
        end

        PDK.logger.info("Ignoring the item value '%{value}' as --force has been set" % { value: item_value }) if current_value.is_a?(Array) && !item_value.nil? && force
        PDK.logger.info('Ignoring --force as the setting is not multi-valued') if !current_value.is_a?(Array) && force

        # FIXME: It'd be nice to shortcircuit deleting default values.  This causes the configuration file
        # to be saved, even though nothing actually changes

        # For most value types, just changing the value to nil is enough, however Arrays are a special case.
        # Unless they're forced, array removal with either remove a single entry (matched by .to_s) or clear the
        # array.  When forced, the array is completed removed just like a string or number.
        if current_value.is_a?(Array) && !force
          # If the user didn't set a value then set the array as empty, otherwise remove that one item
          new_value = item_value.nil? ? [] : current_value.reject { |item| item.to_s == item_value }
          if current_value.count == new_value.count
            if item_value.nil?
              PDK.logger.info("Could not remove '%{name}' as it is already empty" % { name: item_name })
            else
              PDK.logger.info("Could not remove '%{value}' from '%{name}' as it has not been set" % { value: item_value, name: item_name })
            end
            return 0
          end
          PDK.config.set(item_name, new_value, force: true)
        else
          # Set the value to nil for deleting.
          PDK.config.set(item_name, nil, force: true)
        end

        # Output the result to the user
        new_value = PDK.config.get(item_name)
        if current_value.is_a?(Array) && !force
          # Arrays have a special output format. If item_value is nil then the user wanted to empty/clear
          # the array otherwise they just wanted to remove a single entry.
          if item_value.nil?
            PDK.logger.info("Cleared '%{name}' which had a value of '%{from}'" % { name: item_name, from: current_value })
          else
            PDK.logger.info("Removed '%{value}' from '%{name}'" % { value: item_value, name: item_name })
          end
        elsif !new_value.nil?
          PDK.logger.info("Could not remove '%{name}' as it using a default value of '%{to}'" % { name: item_name, to: new_value })
        else
          PDK.logger.info("Removed '%{name}' which had a value of '%{from}'" % { name: item_name, from: current_value })
        end

        # Same output as `get config`
        $stdout.puts '%{name}=%{value}' % { name: item_name, value: new_value }
        0
      end
    end
  end

  @remove_config_cmd = @remove_cmd.define_command do
    name 'config'
    usage 'config [name] [value]'
    summary 'Remove or delete the configuration for <name>'

    option :f, :force, 'Force multi-value configuration settings to be removed instead of emptied.', argument: :forbidden

    run do |opts, args, _cmd|
      exit PDK::CLI::Remove::Config.run(opts, args)
    end
  end
end
