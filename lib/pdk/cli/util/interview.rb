require 'tty-prompt'
require 'pdk/monkey_patches'

module PDK
  module CLI
    module Util
      class Interview < TTY::Prompt::AnswersCollector
        def pastel
          @pastel ||= Pastel.new
        end

        def add_questions(questions)
          questions.each do |question|
            add_question(question)
          end
        end

        def add_question(options = {})
          (@questions ||= {})[options[:name]] = options
        end

        def num_questions
          (@questions ||= {}).count
        end

        def run
          i = 1
          num_questions = @questions.count
          @questions.each do |question_name, question|
            @name = question_name
            @prompt.print pastel.bold(_('[Q %{current_number}/%{questions_total}]') % { current_number: i, questions_total: num_questions }) + ' '
            @prompt.puts pastel.bold(question[:question])
            @prompt.puts question[:help]
            ask(_('-->')) do |q|
              q.required(question.fetch(:required, false))

              if question.key?(:validate_pattern)
                q.validate(question[:validate_pattern], question[:validate_message])
              end

              q.default(question[:default]) if question.key?(:default)
            end
            i += 1
            @prompt.puts ''
          end
          @answers
        rescue TTY::Prompt::Reader::InputInterrupt
          nil
        end
      end
    end
  end
end
