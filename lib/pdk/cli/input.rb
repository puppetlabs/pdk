module PDK
  module CLI
    module Input
      def self.get(default=nil)
        print '--> '
        input = STDIN.gets.chomp.strip
        input = default if input == ''
        input
      end
    end
  end
end
