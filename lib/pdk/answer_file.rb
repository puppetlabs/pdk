require 'json'

module PDK
  # Singleton accessor to the current answer file being used by the PDK.
  #
  # @return [PDK::AnswerFile] The AnswerFile instance currently being used by
  #   the PDK.
  def self.answers
    @answer_file ||= PDK::AnswerFile.new
  end

  class AnswerFile
    attr_reader :answers
    attr_reader :answer_file_path

    # Initialises the AnswerFile object, which stores the responses to certain
    # interactive questions.
    #
    # @param answer_file_path [String, nil] The path on disk to the file where
    #   the answers will be stored and read from. If not specified (or `nil`),
    #   the default path will be used (see #default_answer_file_path).
    #
    # @raise (see #read_from_disk)
    def initialize(answer_file_path = nil)
      @answer_file_path = answer_file_path || default_answer_file_path
      @answers = read_from_disk
    end

    # Retrieve the stored answer to a question.
    #
    # @param question [String] The question name/identifying string.
    #
    # @return [Object] The answer to the question, or `nil` if no answer found.
    def [](question)
      answers[question]
    end

    # Update the stored answers in memory and then save them to disk.
    #
    # @param new_answers [Hash{String => Object}] The new questions and answers
    #   to be merged into the existing answers.
    #
    # @raise [PDK::CLI::FatalError] if the new answers are not provided as
    #   a Hash.
    # @raise (see #save_to_disk)
    def update!(new_answers = {})
      unless new_answers.is_a?(Hash)
        raise PDK::CLI::FatalError, _('Answer file can only be updated with a Hash')
      end

      answers.merge!(new_answers)

      save_to_disk
    end

    private

    # Determine the default path to the answer file.
    #
    # @return [String] The path on disk to the default answer file.
    def default_answer_file_path
      File.join(PDK::Util.cachedir, 'answers.json')
    end

    # Read existing answers into memory from the answer file on disk.
    #
    # @raise [PDK::CLI::FatalError] If the answer file exists but can not be
    #   read.
    #
    # @return [Hash{String => Object}] The existing questions and answers.
    def read_from_disk
      return {} if !File.file?(answer_file_path) || File.zero?(answer_file_path)

      unless File.readable?(answer_file_path)
        raise PDK::CLI::FatalError, _("Unable to open '%{file}' for reading") % {
          file: answer_file_path,
        }
      end

      answers = JSON.parse(File.read(answer_file_path))
      if answers.is_a?(Hash)
        answers
      else
        PDK.logger.warn _("Answer file '%{path}' did not contain a valid set of answers, recreating it") % {
          path: answer_file_path,
        }
        {}
      end
    rescue JSON::JSONError
      PDK.logger.warn _("Answer file '%{path}' did not contain valid JSON, recreating it") % {
        path: answer_file_path,
      }
      {}
    end

    # Save the in memory answer set to the answer file on disk.
    #
    # @raise [PDK::CLI::FatalError] if the answer file can not be written to.
    def save_to_disk
      FileUtils.mkdir_p(File.dirname(answer_file_path))

      File.open(answer_file_path, 'w') do |answer_file|
        answer_file.puts JSON.pretty_generate(answers)
      end
    rescue SystemCallError, IOError => e
      raise PDK::CLI::FatalError, _("Unable to write '%{file}': %{msg}") % {
        file: answer_file_path,
        msg:  e.message,
      }
    end
  end
end
