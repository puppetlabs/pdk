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

      class FileFnmatchPredicate < Cop
        MSG = 'Use PDK::Util::Filesystem.fnmatch? instead of File.fnmatch?'.freeze

        def_node_matcher :file_fnmatch_predicate?,
                         '(send (const nil? :File) {:fnmatch? :fnmatch} ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_fnmatch?,
                        '(send nil? :receive (sym {:fnmatch? :fnmatch}))'

        def on_send(node)
          return unless file_fnmatch_predicate?(node) || (allow_file?(node) && receive_fnmatch?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if file_fnmatch_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileReadablePredicate < Cop
        MSG = 'Use PDK::Util::Filesystem.readable? instead of File.readable?'.freeze

        def_node_matcher :file_readable_predicate?,
                         '(send (const nil? :File) :readable? ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_readable?, '(send nil? :receive (sym :readable?))'

        def on_send(node)
          return unless file_readable_predicate?(node) || (allow_file?(node) && receive_readable?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if file_readable_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsRm < Cop
        MSG = 'Use PDK::Util::Filesystem.rm instead of FileUtils.rm'.freeze

        def_node_matcher :fileutils_rm?,
                         '(send (const nil? :FileUtils) :rm ...)'

        def_node_matcher :allow_fileutils?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :FileUtils))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_rm?, '(send nil? :receive (sym :rm))'

        def on_send(node)
          return unless fileutils_rm?(node) || (allow_fileutils?(node) && receive_rm?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if fileutils_rm?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileRead < Cop
        MSG = 'Use PDK::Util::Filesystem.read_file instead of File.read'.freeze

        def_node_matcher :file_read?,
                         '(send (const nil? :File) :read ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_read?, '(send nil? :receive (sym :read))'

        def on_send(node)
          return unless file_read?(node) || (allow_file?(node) && receive_read?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            if file_read?(node)
              const = node.children[0].loc.expression
              method = node.loc.selector
              new_method = 'read_file'
            else
              const = node.children[0].children[2].loc.expression
              method = node.children[2].receiver.node_parts[0].first_argument.loc.expression
              new_method = ':read_file'
            end
            corrector.replace(const, 'PDK::Util::Filesystem')
            corrector.replace(method, new_method)
          end
        end
      end

      class FileZeroPredicate < Cop
        MSG = 'Use PDK::Util::Filesystem.zero? instead of File.zero?'.freeze

        def_node_matcher :file_zero?,
                         '(send (const nil? :File) :zero? ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_zero?, '(send nil? :receive (sym :zero?))'

        def on_send(node)
          return unless file_zero?(node) || (allow_file?(node) && receive_zero?(node))

          add_offense(node)
        end

        def autocorrect(node)
          ->(corrector) do
            const = if file_zero?(node)
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
