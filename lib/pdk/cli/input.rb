module PDK
  module CLI
    module Input
      # Query the user for a value via STDIN.
      #
      # @param message [String] The message to be displayed to the user before
      # accepting input.
      # @param default [String] The default value to be used if the user
      # provides a blank value.
      #
      # @return [String] The value provided by the user (or the supplied
      # default value).
      def self.get(message, default = nil)
        print message
        if default.nil?
          print ' [(none)]'
        else
          print " [#{default}]"
        end

        print "\n--> "
        input = (STDIN.gets || '').chomp.strip
        input = default if input == ''
        input
      end
    end
  end
end
