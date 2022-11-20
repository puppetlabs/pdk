require 'tty/prompt'
require 'pdk'

module PDK
  module CLI
    module Util
      class Interview < TTY::Prompt::AnswersCollector
        READER = defined?(TTY::Reader) ? TTY::Reader : TTY::Prompt::Reader

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
            @prompt.print pastel.bold('[Q %{current_number}/%{questions_total}]' % { current_number: i, questions_total: num_questions }) + ' '
            @prompt.puts pastel.bold(question[:question])
            @prompt.puts question[:help] if question.key?(:help)

            case question[:type]
            when :yes
              yes?('-->') do |q|
                q.default(question[:default]) if question.key?(:default)
              end
            when :multi_select
              multi_select('-->', per_page: question[:choices].count) do |q|
                q.enum ')'
                q.default(*question[:default]) if question.key?(:default)

                question[:choices].each do |text, metadata|
                  q.choice text, metadata
                end
              end
            else
              ask('-->') do |q|
                q.required(question.fetch(:required, false))

                if question.key?(:validate_pattern)
                  q.validate(question[:validate_pattern], question[:validate_message])
                end

                q.default(question[:default]) if question.key?(:default)
              end
            end
            i += 1
            @prompt.puts ''
          end
          @answers
        rescue READER::InputInterrupt
          nil
        end
      end
    end
  end
end
