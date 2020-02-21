require 'pdk'

module PDK
  class AnswerFile
    # Determine the default path to the answer file.
    #
    # @return [String] The path on disk to the default answer file.
    def self.default_answer_file_path
      PDK::Util::Filesystem.expand_path(File.join(PDK::Util.cachedir, 'answers.json'))
    end
  end
end
