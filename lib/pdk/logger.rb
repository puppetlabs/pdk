require 'logger'

module PDK
  def self.logger
    @logger ||= PDK::Logger.new
  end

  class Logger < ::Logger
    def initialize
      # TODO: Decide where log output goes, probably stderr?
      super(STDOUT)

      # TODO: Decide on output format.
      self.formatter = proc do |severity,datetime,progname,msg|
        "pdk (#{severity}): #{msg}\n"
      end
    end
  end
end
