module PDK::CLI
  @get_config_cmd = @get_cmd.define_command do
    name 'config'
    usage 'config [name]'
    summary 'Retrieve the configuration for <name>. If not specified, retrieve all configuration settings'

    run do |_opts, args, _cmd|
      item_name = args[0]
      resolved_config = PDK.config.resolve(item_name)
      # If the user wanted to know a setting but it doesn't exist, raise an error
      if resolved_config.empty? && !item_name.nil?
        PDK.logger.error("Configuration item '%{name}' does not exist" % { name: item_name })
        exit 1
      end
      # If the user requested a setting and it's the only one resolved, then just output the value
      if resolved_config.count == 1 && resolved_config.keys[0] == item_name
        puts '%{value}' % { value: resolved_config.values[0] }
        exit 0
      end
      # Otherwise just output everything
      resolved_config.keys.sort.each { |key| puts '%{name}=%{value}' % { name: key, value: resolved_config[key] } }
    end
  end
end
