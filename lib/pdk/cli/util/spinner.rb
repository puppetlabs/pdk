require 'tty-spinner'

# Replace the built-in tty check in tty-spinner with our own implementation
# that allows us to mock the behaviour during acceptance tests.
module TTY
  class Spinner
    def tty?
      require 'pdk/cli/util'

      PDK::CLI::Util.interactive?
    end
  end
end
