module PDK::CLI
  module Set
    module Config
      ALLOWED_TYPE_NAMES = %w[array boolean number string].freeze

      # :nocov:
      def self.pretty_allowed_names
        ALLOWED_TYPE_NAMES.map { |name| "'#{name}'" }.join(', ')
      end
      # :nocov:

      def self.transform_value(type_name, value)
        normalized_name = type_name.downcase.strip
        unless ALLOWED_TYPE_NAMES.include?(normalized_name)
          raise PDK::CLI::ExitWithError, _('Unknown type %{type_name}. Expected one of %{allowed}') % { type_name: type_name, allowed: pretty_allowed_names }
        end

        # Short circuit string conversions as it's trivial
        if normalized_name == 'string'
          raise PDK::CLI::ExitWithError, _('An error occured converting \'%{value}\' into a %{type_name}') % { value: value.nil? ? 'nil' : value, type_name: type_name } unless value.is_a?(String)
          return value
        end

        begin
          case normalized_name
          when 'array'
            convert_to_array(value)
          when 'boolean'
            convert_to_boolean(value)
          when 'number'
            convert_to_number(value)
          else
            value
          end
        rescue ArgumentError, TypeError
          raise PDK::CLI::ExitWithError, _('An error occured converting \'%{value}\' into a %{type_name}') % { value: value.nil? ? 'nil' : value, type_name: type_name }
        end
      end

      # :nocov:
      def self.convert_to_array(value)
        return [] if value.nil?
        value.is_a?(Array) ? value : [value]
      end
      private_class_method :convert_to_array

      def self.convert_to_boolean(value)
        string_val = value.to_s.strip.downcase

        return true  if %w[yes true -1].include?(string_val)
        return false if %w[no false 0].include?(string_val)

        raise ArgumentError
      end
      private_class_method :convert_to_boolean

      def self.convert_to_number(value)
        float_val = Float(value)
        # Return an Integer if this is actually and Integer, otherwise return the float
        (float_val.truncate == float_val) ? float_val.truncate : float_val
      end
      private_class_method :convert_to_number
      # :nocov:

      def self.run(opts, args)
        item_name = (args.count > 0) ? args[0] : nil
        item_value = (args.count > 1) ? args[1] : nil

        opts[:type] = opts[:as] if opts[:type].nil? && !opts[:as].nil?
        force = opts[:force] || false

        # Transform the value if we need to
        item_value = PDK::CLI::Set::Config.transform_value(opts[:type], item_value) unless opts[:type].nil?

        raise PDK::CLI::ExitWithError, _('Configuration name is required') if item_name.nil?
        raise PDK::CLI::ExitWithError, _('Configuration value is required. If you wish to remove a value use \'pdk remove config\'') if item_value.nil?

        current_value = PDK.config.get(item_name)
        raise PDK::CLI::ExitWithError, _("The configuration item '%{name}' can not have a value set.") % { name: item_name } if current_value.is_a?(PDK::Config::Namespace)

        item_value = item_value
        # If we're forcing the value, don't do any munging
        unless force
          # Check if the setting already exists
          if current_value.is_a?(Array) && current_value.include?(item_value)
            PDK.logger.info(_("No changes made to '%{name}' as it already contains value '%{to}'") % { name: item_name, to: item_value })
            return 0
          end
        end

        # TODO: Trap Argument errors ?
        new_value = PDK.config.set(item_name, item_value, force: opts[:force])
        if current_value.nil? || force
          PDK.logger.info(_("Set initial value of '%{name}' to '%{to}'") % { name: item_name, to: new_value })
        elsif current_value.is_a?(Array)
          # Arrays have a special output format
          PDK.logger.info(_("Added new value '%{to}' to '%{name}'") % { name: item_name, to: item_value })
        else
          PDK.logger.info(_("Changed existing valuie of '%{name}' from '%{from}' to '%{to}'") % { name: item_name, from: current_value, to: new_value })
        end

        # Same output as `get config`
        $stdout.puts _('%{name}=%{value}') % { name: item_name, value: PDK.config.get(item_name) }
        0
      end
    end
  end

  @set_config_cmd = @set_cmd.define_command do
    name 'config'
    usage _('config [name] [value]')
    summary _('Set or update the configuration for <name>')

    option :f, :force, _('Force the configuration setting to be overwitten.'), argument: :forbidden

    option :t, :type, _('The type of value to set. Acceptable values: %{values}') % { values: PDK::CLI::Set::Config.pretty_allowed_names }, argument: :required
    option nil, :as, _('Alias of --type'), argument: :required

    run do |opts, args, _cmd|
      exit PDK::CLI::Set::Config.run(opts, args)
    end
  end
end
