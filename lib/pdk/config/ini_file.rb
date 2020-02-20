require 'pdk'

module PDK
  class Config
    # Represents a configuration file using the INI file format
    class IniFile < Namespace
      # Ini Files have very strict valdiation rules which are set in the IniFileSetting class
      # @see PDK::Config::Namespace.default_setting_class
      def default_setting_class
        PDK::Config::IniFileSetting
      end

      # Parses an IniFile document.
      #
      # @see PDK::Config::Namespace.parse_file
      def parse_file(filename)
        raise unless block_given?
        data = load_data(filename)
        return if data.nil? || data.empty?

        ini_file = IniFileImpl.parse(data)
        ini_file.to_hash.each do |name, value|
          begin
            new_setting = PDK::Config::IniFileSetting.new(name, self, value)
          rescue StandardError
            # We just ignore invalid initial settings
            new_setting = PDK::Config::IniFileSetting.new(name, self, nil)
          end

          yield name, new_setting
        end
      end

      # Serializes object data into an INI file string.
      #
      # @see PDK::Config::Namespace.serialize_data
      def serialize_data(data)
        default_lines = ''
        lines = ''
        data.each do |name, value|
          next if value.nil?
          if value.is_a?(Hash)
            # Hashes are an INI section
            lines += "\n[#{name}]\n"
            value.each do |child_name, child_value|
              next if child_value.nil?
              lines += "#{child_name} = #{munge_serialized_value(child_value)}\n"
            end
          else
            default_lines += "#{name} = #{munge_serialized_value(value)}\n"
          end
        end

        default_lines + lines
      end

      private

      def munge_serialized_value(value)
        value = value.to_s unless value.is_a?(String)
        # Add enclosing quotes if there's a space in the value
        value = '"' + value + '"' if value.include?(' ')
        value
      end

      # Adapted from https://raw.githubusercontent.com/puppetlabs/puppet/6c257fc7827989c2af2901f974666f0f23611153/lib/puppet/settings/ini_file.rb
      # rubocop:disable Style/RegexpLiteral
      # rubocop:disable Style/PerlBackrefs
      # rubocop:disable Style/RedundantSelf
      # rubocop:disable Style/StringLiterals
      class IniFileImpl
        DEFAULT_SECTION_NAME = 'default_section_name'.freeze

        def self.parse(config_fh)
          config = new([DefaultSection.new])
          config_fh.each_line do |line|
            case line.chomp
            when /^(\s*)\[([[:word:]]+)\](\s*)$/
              config.append(SectionLine.new($1, $2, $3))
            when /^(\s*)([[:word:]]+)(\s*=\s*)(.*?)(\s*)$/
              config.append(SettingLine.new($1, $2, $3, $4, $5))
            else
              config.append(Line.new(line))
            end
          end

          config
        end

        def initialize(lines = [])
          @lines = lines
        end

        def to_hash
          result = {}

          current_section_name = nil
          @lines.each do |line|
            if line.instance_of?(SectionLine)
              current_section_name = line.name
              result[current_section_name] = {}
            elsif line.instance_of?(SettingLine)
              if current_section_name.nil?
                result[line.name] = munge_value(line.value)
              else
                result[current_section_name][line.name] = munge_value(line.value)
              end
            end
          end

          result
        end

        def munge_value(value)
          value = value.to_s unless value.is_a?(String)
          # Strip enclosing quotes
          value = value.slice(1...-1) if value.start_with?('"') && value.end_with?('"')
          value
        end

        def append(line)
          line.previous = @lines.last
          @lines << line
        end

        module LineNumber
          attr_accessor :previous

          def line_number
            line = 0
            previous_line = previous
            while previous_line
              line += 1
              previous_line = previous_line.previous
            end
            line
          end
        end

        Line = Struct.new(:text) do
          include LineNumber

          def to_s
            text
          end
        end

        SettingLine = Struct.new(:prefix, :name, :infix, :value, :suffix) do
          include LineNumber

          def to_s
            "#{prefix}#{name}#{infix}#{value}#{suffix}"
          end

          def ==(other)
            super(other) && self.line_number == other.line_number
          end
        end

        SectionLine = Struct.new(:prefix, :name, :suffix) do
          include LineNumber

          def to_s
            "#{prefix}[#{name}]#{suffix}"
          end
        end

        class DefaultSection < SectionLine
          attr_accessor :write_sectionline

          def initialize
            @write_sectionline = false
            super("", DEFAULT_SECTION_NAME, "")
          end
        end
      end
      # rubocop:enable Style/StringLiterals
      # rubocop:enable Style/RedundantSelf
      # rubocop:enable Style/PerlBackrefs
      # rubocop:enable Style/RegexpLiteral
    end
  end
end
