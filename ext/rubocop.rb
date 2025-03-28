module RuboCop
  module Cop
    module PDK
      class FileFilePredicate < Base
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
          lambda do |corrector|
            const = if file_file_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileExistPredicate < Base
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
          lambda do |corrector|
            const = if file_exist_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileDirectoryPredicate < Base
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
          lambda do |corrector|
            const = if file_directory_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsMkdirP < Base
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
          lambda do |corrector|
            const = if fileutils_mkdir_p?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileExpandPath < Base
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
          lambda do |corrector|
            const = if file_expand_path?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class DirGlob < Base
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
          lambda do |corrector|
            const = if dir_glob?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileFnmatchPredicate < Base
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
          lambda do |corrector|
            const = if file_fnmatch_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileReadablePredicate < Base
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
          lambda do |corrector|
            const = if file_readable_predicate?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsRm < Base
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
          lambda do |corrector|
            const = if fileutils_rm?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileRead < Base
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
          lambda do |corrector|
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

      class FileZeroPredicate < Base
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
          lambda do |corrector|
            const = if file_zero?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileStat < Base
        MSG = 'Use PDK::Util::Filesystem.stat instead of File.stat'.freeze

        def_node_matcher :file_stat?,
                         '(send (const nil? :File) :stat ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_stat?, '(send nil? :receive (sym :stat))'

        def on_send(node)
          return unless file_stat?(node) || (allow_file?(node) && receive_stat?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            const = if file_stat?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class DirExistPredicate < Base
        MSG = 'Use PDK::Util::Filesystem.directory? instead of Dir.exist?'.freeze

        def_node_matcher :dir_exist?,
                         '(send (const nil? :Dir) {:exist? :exists?} ...)'

        def_node_matcher :allow_dir?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :Dir))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_exist?, '(send nil? :receive (sym {:exist? :exists?}))'

        def on_send(node)
          return unless dir_exist?(node) || (allow_dir?(node) && receive_exist?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            if dir_exist?(node)
              const = node.children[0].loc.expression
              method = node.loc.selector
              new_method = 'directory?'
            else
              const = node.children[0].children[2].loc.expression
              method = node.children[2].receiver.node_parts[0].first_argument.loc.expression
              new_method = ':directory?'
            end
            corrector.replace(const, 'PDK::Util::Filesystem')
            corrector.replace(method, new_method)
          end
        end
      end

      class DirBrackets < Base
        MSG = 'Use PDK::Util::Filesystem.glob instead of Dir[]'.freeze

        def_node_matcher :dir_brackets?,
                         '(send (const nil? :Dir) :[] ...)'

        def_node_matcher :allow_dir?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :Dir))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_brackets?, '(send nil? :receive (sym :[]))'

        def on_send(node)
          return unless dir_brackets?(node) || (allow_dir?(node) && receive_brackets?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            if dir_brackets?(node)
              const = node.children[0].loc.expression
              method = node.loc.selector
              new_method = ".glob(#{node.arguments.map(&:source).join(', ')})"
            else
              const = node.children[0].children[2].loc.expression
              method = node.children[2].receiver.node_parts[0].first_argument.loc.expression
              new_method = ':glob'
            end
            corrector.replace(const, 'PDK::Util::Filesystem')
            corrector.replace(method, new_method)
          end
        end
      end

      class FileOpen < Base
        MSG = 'Use PDK::Util::Filesystem.read_file or PDK::Util::Filesystem.write_file instead of File.open'.freeze

        def_node_matcher :file_open?,
                         '(send (const nil? :File) :open ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_open?, '(send nil? :receive (sym :open))'

        def on_send(node)
          return unless file_open?(node) || (allow_file?(node) && receive_open?(node))

          add_offense(node)
        end
      end

      class FileSymlinkPredicate < Base
        MSG = 'Use PDK::Util::Filesystem.symlink? instead of File.symlink?'.freeze

        def_node_matcher :file_symlink?,
                         '(send (const nil? :File) :symlink? ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_symlink?, '(send nil? :receive (sym :symlink?))'

        def on_send(node)
          return unless file_symlink?(node) || (allow_file?(node) && receive_symlink?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            const = if file_symlink?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileDelete < Base
        MSG = 'Use PDK::Util::Filesystem.rm instead of File.delete'.freeze

        def_node_matcher :file_delete?,
                         '(send (const nil? :File) :delete ...)'

        def_node_matcher :allow_file?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :File))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_delete?, '(send nil? :receive (sym :delete))'

        def on_send(node)
          return unless file_delete?(node) || (allow_file?(node) && receive_delete?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            const = if file_delete?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsRMF < Base
        MSG = 'Use PDK::Util::Filesystem.rm_f instead of FileUtils.rm_f'.freeze

        def_node_matcher :fileutils_rm_f?,
                         '(send (const nil? :FileUtils) :rm_f ...)'

        def_node_matcher :allow_fileutils?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :FileUtils))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_rm_f?, '(send nil? :receive (sym :rm_f))'

        def on_send(node)
          return unless fileutils_rm_f?(node) || (allow_fileutils?(node) && receive_rm_f?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            const = if fileutils_rm_f?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsRMRF < Base
        MSG = 'Use PDK::Util::Filesystem.rm_rf instead of FileUtils.rm_rf'.freeze

        def_node_matcher :fileutils_rm_rf?,
                         '(send (const nil? :FileUtils) :rm_rf ...)'

        def_node_matcher :allow_fileutils?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :FileUtils))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_rm_rf?, '(send nil? :receive (sym :rm_rf))'

        def on_send(node)
          return unless fileutils_rm_rf?(node) || (allow_fileutils?(node) && receive_rm_rf?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            const = if fileutils_rm_rf?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsCP < Base
        MSG = 'Use PDK::Util::Filesystem.cp instead of FileUtils.cp'.freeze

        def_node_matcher :fileutils_cp?,
                         '(send (const nil? :FileUtils) :cp ...)'

        def_node_matcher :allow_fileutils?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :FileUtils))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_cp?, '(send nil? :receive (sym :cp))'

        def on_send(node)
          return unless fileutils_cp?(node) || (allow_fileutils?(node) && receive_cp?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            const = if fileutils_cp?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsMV < Base
        MSG = 'Use PDK::Util::Filesystem.mv instead of FileUtils.mv'.freeze

        def_node_matcher :fileutils_mv?,
                         '(send (const nil? :FileUtils) :mv ...)'

        def_node_matcher :allow_fileutils?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :FileUtils))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_mv?, '(send nil? :receive (sym :mv))'

        def on_send(node)
          return unless fileutils_mv?(node) || (allow_fileutils?(node) && receive_mv?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            const = if fileutils_mv?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class FileUtilsRemoveDir < Base
        MSG = 'Use PDK::Util::Filesystem.rm_rf instead of FileUtils.remove_dir'.freeze

        def_node_matcher :fileutils_remove_dir?,
                         '(send (const nil? :FileUtils) :remove_dir ...)'

        def_node_matcher :allow_fileutils?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :FileUtils))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_remove_dir?, '(send nil? :receive (sym :remove_dir))'

        def on_send(node)
          return unless fileutils_remove_dir?(node) || (allow_fileutils?(node) && receive_remove_dir?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            if fileutils_remove_dir?(node)
              const = node.children[0].loc.expression
              method = node.loc.selector
              new_method = 'rm_rf'
            else
              const = node.children[0].children[2].loc.expression
              method = if node.children[2].receiver
                         node.children[2].receiver.node_parts[0].first_argument.loc.expression
                       else
                         node.children[2].first_argument.loc.expression
                       end
              new_method = ':rm_rf'
            end
            corrector.replace(const, 'PDK::Util::Filesystem')
            corrector.replace(method, new_method)
          end
        end
      end

      class FileUtilsRemoveEntrySecure < Base
        MSG = 'Use PDK::Util::Filesystem.remove_entry_secure instead of FileUtils.remove_entry_secure'.freeze

        def_node_matcher :fileutils_remove_entry_secure?,
                         '(send (const nil? :FileUtils) :remove_entry_secure ...)'

        def_node_matcher :allow_fileutils?, <<-MATCHER
          (send
            (send nil? {:allow :expect} (const nil? :FileUtils))
            {:to :not_to}
            ...)
        MATCHER

        def_node_search :receive_remove_entry_secure?, '(send nil? :receive (sym :remove_entry_secure))'

        def on_send(node)
          return unless fileutils_remove_entry_secure?(node) ||
                        (allow_fileutils?(node) && receive_remove_entry_secure?(node))

          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            const = if fileutils_remove_entry_secure?(node)
                      node.children[0].loc.expression
                    else
                      node.children[0].children[2].loc.expression
                    end
            corrector.replace(const, 'PDK::Util::Filesystem')
          end
        end
      end

      class SmartQuotes < Base
        MSG = 'Use ASCII quotes instead of Unicode smart quotes'.freeze
        SINGLE_QUOTES_PAT = /(?:\u2018|\u2019)/
        DOUBLE_QUOTES_PAT = /(?:\u201C|\u201D)/

        def on_str(node)
          return unless node.loc.respond_to?(:begin) && node.loc.begin
          return if part_of_ignored_node?(node)

          add_offense(node) if smart_quotes?(node)
        end

        def on_regexp(node)
          add_offense(node) if smart_quotes?(node)
        end

        def smart_quotes?(node)
          smart_single_quotes?(node) || smart_double_quotes?(node)
        end

        def smart_single_quotes?(node)
          node.source.index(SINGLE_QUOTES_PAT)
        end

        def smart_double_quotes?(node)
          node.source.index(DOUBLE_QUOTES_PAT)
        end

        def autocorrect(node)
          lambda do |corrector|
            if smart_single_quotes?(node)
              new_str = node.source.gsub(SINGLE_QUOTES_PAT, "'")
              if new_str.start_with?("'")
                new_str[0] = '"'
                new_str[-1] = '"'
              end
              corrector.replace(node.loc.expression, new_str)
            end
          end
        end
      end
    end
  end
end
