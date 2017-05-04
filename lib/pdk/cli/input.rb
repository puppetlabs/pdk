module PDK
  module CLI
    module Input
      def self.get(message, default=nil)
        print message
        if default.nil?
          print " [(none)]"
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
