module PDK
  class Report
    def initialize(path, format = nil)
      @path = path
      @format = format || self.class.default_format
    end

    def self.formats
      @report_formats ||= %w[junit text].freeze
    end

    def self.default_format
      'junit'
    end

    def self.default_target
      'stdout' # TODO: actually write to stdout
    end

    def write(text)
      if @format == 'junit'
        report = prepare_junit(text)
      elsif @format == 'text'
        report = prepare_text(text)
      end

      File.open(@path, 'a') { |f| f.write(report) }
    end

    def prepare_junit(text)
      "junit: #{text}"
    end

    def prepare_text(text)
      "text: #{text}"
    end
  end
end
