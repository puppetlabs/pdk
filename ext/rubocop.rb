module RuboCop
  module Cop
    module PDK
      class FileFilePredicate < Cop
        MSG = 'Use PDK::Util::Filesystem.file? instead of File.file?'.freeze

        def_node_matcher :file_file_predicate?,
                         '(send (const nil? :File) :file? ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_file?, '(send nil? :receive (sym :file?))'

        def on_send(node)
          return unless file_file_predicate?(node) || (allow_file?(node) && receive_file?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if file_file_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end
    end
  end
end
