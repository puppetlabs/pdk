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

      class FileExistPredicate < Cop
        MSG = 'Use PDK::Util::Filesystem.exist? instead of File.exist?'.freeze

        def_node_matcher :file_exist_predicate?,
                         '(send (const nil? :File) :exist? ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_exist?, '(send nil? :receive (sym :exist?))'

        def on_send(node)
          return unless file_exist_predicate?(node) || (allow_file?(node) && receive_exist?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if file_exist_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileDirectoryPredicate < Cop
        MSG = 'Use PDK::Util::Filesystem.directory? instead of File.directory?'.freeze

        def_node_matcher :file_directory_predicate?,
                         '(send (const nil? :File) :directory? ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_directory?,
                        '(send nil? :receive (sym :directory?))'

        def on_send(node)
          return unless file_directory_predicate?(node) || (allow_file?(node) && receive_directory?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if file_directory_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsMkdirP < Cop
        MSG = 'Use PDK::Util::Filesystem.mkdir_p instead of FileUtils.mkdir_p'.freeze

        def_node_matcher :fileutils_mkdir_p?,
                         '(send (const nil? :FileUtils) :mkdir_p ...)'

        def_node_matcher :allow_fileutils?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :FileUtils))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_mkdir_p?,
                        '(send nil? :receive (sym :mkdir_p))'

        def on_send(node)
          return unless fileutils_mkdir_p?(node) || (allow_fileutils?(node) && receive_mkdir_p?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if fileutils_mkdir_p?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileExpandPath < Cop
        MSG = 'Use PDK::Util::Filesystem.expand_path instead of File.expand_path'.freeze

        def_node_matcher :file_expand_path?,
                         '(send (const nil? :File) :expand_path ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_expand_path?,
                        '(send nil? :receive (sym :expand_path))'

        def on_send(node)
          return unless file_expand_path?(node) || (allow_file?(node) && receive_expand_path?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if file_expand_path?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class DirGlob < Cop
        MSG = 'Use PDK::Util::Filesystem.glob instead of Dir.glob'.freeze

        def_node_matcher :dir_glob?,
                         '(send (const nil? :Dir) :glob ...)'

        def_node_matcher :allow_dir?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :Dir))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_glob?, '(send nil? :receive (sym :glob))'

        def on_send(node)
          return unless dir_glob?(node) || (allow_dir?(node) && receive_glob?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if dir_glob?(node)
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
