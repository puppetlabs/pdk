module PDK
  module Util
    # Processes a given string, looking for JSON objects and parsing them.
    #
    # @example A string with a JSON object and some junk characters
    #   PDK::Util::JSONFinder.new('foo{"bar":1}').objects
    #   => [{ 'bar' => 1 }]
    #
    # @example A string with mulitple JSON objects
    #   PDK::Util::JSONFinder.new('foo{"bar":1}baz{"gronk":2}').objects
    #   => [{ 'bar' => 1 }, { 'gronk' => 2 }]
    class JSONFinder
      # Creates a new instance of PDK::Util::JSONFinder.
      #
      # @param string [String] the string to find JSON objects inside of.
      #
      # @return [PDK::Util::JSONFinder] a new PDK::Util::JSONFinder object.
      def initialize(string)
        require 'strscan'

        @scanner = StringScanner.new(string)
      end

      # Returns the parsed JSON objects from the string.
      #
      # @return [Array[Hash]] the parsed JSON objects present in the string.
      def objects
        return @objects unless @objects.nil?

        require 'json'

        until @scanner.eos?
          @scanner.getch until @scanner.peek(1) == '{' || @scanner.eos?

          (@objects ||= []) << begin
                                 JSON.parse(read_object(true) || '')
                               rescue JSON::ParserError
                                 nil
                               end
        end

        return [] if @objects.nil?
        @objects = @objects.compact
      end

      private

      # Recursively process the string to extract a complete JSON object.
      #
      # @param new_object [Boolean] Set to true if processing a new object to
      #   capture the opening brace. Set to false if being called recursively
      #   where the opening brace has already been captured.
      #
      # @return [String] The matched substring containing a JSON object.
      def read_object(new_object = false)
        matched_text = new_object ? @scanner.getch : ''

        until @scanner.eos?
          text = @scanner.scan_until(%r{(?:(?<!\\)"|\{|\})})
          unless text
            @scanner.terminate
            return nil
          end
          matched_text += text

          case @scanner.matched
          when '}'
            break
          when '"'
            text = @scanner.scan_until(%r{(?<!\\)"})
            unless text
              @scanner.terminate
              return nil
            end
            matched_text += text
          else
            matched_text += read_object
          end
        end

        matched_text
      end
    end
  end
end
