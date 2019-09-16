require 'pdk/cli/exec'

module PDK
  module Util
    module PuppetStrings
      class NoObjectError < StandardError; end
      class RunError < StandardError; end
      class NoGeneratorError < StandardError; end

      # Runs Puppet for the purposes of generating puppet-strings output.
      #
      # @param *args [String] additional parameters to pass to puppet.
      #
      # @return [Hash{Symbol=>Object}] the result of the command execution.
      def self.puppet(*args)
        PDK::Util::Bundler.ensure_binstubs!('puppet')

        argv = [File.join(PDK::Util.module_root, 'bin', 'puppet')] + args
        argv.unshift(File.join(PDK::Util::RubyVersion.bin_path, 'ruby.exe')) if Gem.win_platform?

        command = PDK::CLI::Exec::Command.new(*argv).tap do |c|
          c.context = :module
          c.add_spinner(_('Examining module contents'))
        end

        command.execute!
      end

      # Generates and parses the JSON output from puppet-strings.
      #
      # @returns [Hash{String=>Object}] the parsed puppet-strings output.
      #
      # @raises [PDK::Util::PuppetStrings::RunError] if the puppet-strings
      #   command exits non-zero.
      # @raises [PDK::Util::PuppetStrings::RunError] if the puppet-strings
      #   command outputs invalid JSON.
      def self.generate_hash
        result = puppet('strings', 'generate', '--format', 'json')

        raise RunError, result[:stderr] unless result[:exit_code].zero?

        JSON.parse(result[:stdout])
      rescue JSON::ParserError => e
        PDK.logger.debug(e)
        raise RunError, _('Unable to parse puppet-strings output')
      end

      # Searches the puppet-strings result to find the definition of the named
      # object.
      #
      # @param name [String] the name of the object definition to search for.
      #   If the object name is not prepended with the module name,
      #   "#{module_name}::#{object_name}" will also be search for.
      #
      # @returns [Array[PDK::Generate::PuppetObject, Hash{String=>Object}]] the
      #   appropriate generator class for the object as the first element and
      #   the puppet-strings description hash for the definition.
      #
      # @raises [PDK::Util::PuppetStrings::NoObjectError] if the named object
      #   can not be found in the puppet-strings output.
      # @raises [PDK::Util::PuppetStrings::NoGeneratorError] if the named
      #   object does not have a corresponding PDK generator class.
      def self.find_object(name)
        module_name = PDK::Util.module_metadata['name'].rpartition('-').last

        object_names = [name]
        object_names << "#{module_name}::#{name}" unless name.start_with?("#{module_name}::")

        known_objects = generate_hash
        object_type = known_objects.keys.find do |obj_type|
          known_objects[obj_type].any? { |obj| object_names.include?(obj['name']) }
        end

        raise NoObjectError if object_type.nil?

        generator = find_generator(object_type)

        raise NoGeneratorError, object_type if generator.nil?

        [generator, known_objects[object_type].find { |obj| object_names.include?(obj['name']) }]
      end

      # Generate a list of all objects that PDK has a generator for.
      #
      # @returns [Array[Array[PDK::Generate::PuppetObject,
      #   Array[Hash{String=>Object}]]]] an associative array where the first
      #   element of each pair is the generator class and the second element of
      #   each pair is an array of description hashes from puppet-strings.
      def self.all_objects
        generators = PDK::Generate::GENERATORS.select do |gen|
          gen.respond_to?(:puppet_strings_type) && !gen.puppet_strings_type.nil?
        end

        known_objects = generate_hash

        generators.map { |gen| [gen, known_objects[gen.puppet_strings_type]] }.reject do |_, obj|
          obj.nil? || obj.empty?
        end
      end

      # Evaluates the mapping of puppet-strings object type to PDK generator
      # class.
      #
      # @param type [String] the object type as returned from puppet-strings.
      #
      # @returns [PDK:Generate::PuppetObject,nil] a child of
      #   PDK::Generate::PuppetObject or nil a suitable generator is not found.
      #
      # @example
      #   PDK::Util::PuppetStrings.find_generator('puppet_classes')
      #   => PDK::Generate::PuppetClass
      def self.find_generator(type)
        PDK::Generate::GENERATORS.find do |gen|
          gen.respond_to?(:puppet_strings_type) && gen.puppet_strings_type == type
        end
      end
    end
  end
end
