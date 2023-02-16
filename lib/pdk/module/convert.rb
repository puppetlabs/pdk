require 'pdk'

module PDK
  module Module
    class Convert
      def self.invoke(module_dir, options)
        new(module_dir, options).run
      end

      attr_reader :module_dir

      attr_reader :options

      def initialize(module_dir, options = {})
        @module_dir = module_dir
        @options = options
      end

      def convert?
        instance_of?(PDK::Module::Convert)
      end

      def run
        stage_changes!

        unless update_manager.changes?
          if adding_tests?
            add_tests!
            print_result 'Convert completed'
          else
            require 'pdk/report'

            PDK::Report.default_target.puts('No changes required.')
          end

          return
        end

        print_summary

        full_report('convert_report.txt') unless update_manager.changes[:modified].empty?

        return if noop?

        unless force?
          require 'pdk/cli/util'

          PDK.logger.info 'Module conversion is a potentially destructive action. ' \
                          'Ensure that you have committed your module to a version control ' \
                          'system or have a backup, and review the changes above before continuing.'
          continue = PDK::CLI::Util.prompt_for_yes('Do you want to continue and make these changes to your module?')
          return unless continue
        end

        # Remove these files straight away as these changes are not something
        # that the user needs to review.
        update_manager.unlink_file('Gemfile.lock')
        update_manager.unlink_file(File.join('.bundle', 'config'))

        update_manager.sync_changes!

        require 'pdk/util/bundler'
        PDK::Util::Bundler.ensure_bundle!

        add_tests! if adding_tests?

        print_result 'Convert completed'
      end

      def noop?
        options[:noop]
      end

      def force?
        options[:force]
      end

      def add_tests?
        options[:'add-tests']
      end

      def adding_tests?
        add_tests? && missing_tests?
      end

      def missing_tests?
        !available_test_generators.empty?
      end

      def available_test_generators
        # Only select generators which can run and have no pre-existing files
        test_generators.select do |gen|
          if gen.can_run?
            gen.template_files.none? { |_, dst_path| PDK::Util::Filesystem.exist?(File.join(gen.context.root_path, dst_path)) }
          else
            false
          end
        end
      end

      def test_generators(context = PDK.context)
        return @test_generators unless @test_generators.nil?
        require 'pdk/util/puppet_strings'

        test_gens = PDK::Util::PuppetStrings.all_objects.map do |generator, objects|
          (objects || []).map do |obj|
            generator.new(context, obj['name'], spec_only: true)
          end
        end

        @test_generators = test_gens.flatten
      end

      def stage_tests!(manager)
        available_test_generators.each do |gen|
          gen.stage_changes(manager)
        end
        manager
      end

      def add_tests!
        update_manager.clear!
        stage_tests!(update_manager)

        if update_manager.changes?
          update_manager.sync_changes!
          print_summary
        else
          PDK::Report.default_target.puts('No test changes required.')
        end
      end

      def stage_changes!(context = PDK.context)
        require 'pdk/util/filesystem'

        metadata_path = File.join(module_dir, 'metadata.json')

        PDK::Template.with(template_uri, context) do |template_dir|
          new_metadata = update_metadata(metadata_path, template_dir.metadata)
          if options[:noop] && new_metadata.nil?
            update_manager.add_file(metadata_path, '')
          elsif PDK::Util::Filesystem.file?(metadata_path)
            update_manager.modify_file(metadata_path, new_metadata.to_json)
          else
            update_manager.add_file(metadata_path, new_metadata.to_json)
          end

          # new_metadata == nil when creating a new module but with --noop@
          module_name = new_metadata.nil? ? 'new-module' : new_metadata.data['name']
          metadata_for_render = new_metadata.nil? ? {} : new_metadata.data

          template_dir.render_new_module(module_name, metadata_for_render) do |relative_file_path, file_content, file_status|
            absolute_file_path = File.join(module_dir, relative_file_path)
            case file_status
            when :unmanage
              PDK.logger.debug("skipping '%{path}'" % { path: absolute_file_path })
            when :delete
              update_manager.remove_file(absolute_file_path)
            when :init
              if convert? && !PDK::Util::Filesystem.exist?(absolute_file_path)
                update_manager.add_file(absolute_file_path, file_content)
              end
            when :manage
              if PDK::Util::Filesystem.exist?(absolute_file_path)
                update_manager.modify_file(absolute_file_path, file_content)
              else
                update_manager.add_file(absolute_file_path, file_content)
              end
            end
          end
        end
      rescue ArgumentError => e
        raise PDK::CLI::ExitWithError, e
      end

      def update_manager
        require 'pdk/module/update_manager'

        @update_manager ||= PDK::Module::UpdateManager.new
      end

      def template_uri
        require 'pdk/util/template_uri'

        @template_uri ||= PDK::Util::TemplateURI.new(options)
      end

      def update_metadata(metadata_path, template_metadata)
        require 'pdk/generate/module'
        require 'pdk/util/filesystem'
        require 'pdk/module/metadata'

        if PDK::Util::Filesystem.file?(metadata_path)
          unless PDK::Util::Filesystem.readable?(metadata_path)
            raise PDK::CLI::ExitWithError, 'Unable to update module metadata; %{path} exists but it is not readable.' % {
              path: metadata_path,
            }
          end

          begin
            metadata = PDK::Module::Metadata.from_file(metadata_path)
            new_values = PDK::Module::Metadata::DEFAULTS.select do |key, _|
              !metadata.data.key?(key) || metadata.data[key].nil? ||
                (key == 'requirements' && metadata.data[key].empty?)
            end
            metadata.update!(new_values)
          rescue ArgumentError
            metadata = PDK::Generate::Module.prepare_metadata(options) unless options[:noop]
          end
        elsif PDK::Util::Filesystem.exist?(metadata_path)
          raise PDK::CLI::ExitWithError, 'Unable to update module metadata; %{path} exists but it is not a file.' % {
            path: metadata_path,
          }
        else
          return if options[:noop]

          project_dir = File.basename(Dir.pwd)
          options[:module_name] = project_dir.split('-', 2).compact[-1]
          options[:prompt] = false
          options[:'skip-interview'] = true if options[:force]

          metadata = PDK::Generate::Module.prepare_metadata(options)
        end

        metadata.update!(template_metadata)
        metadata
      end

      def summary
        summary = {}
        update_manager.changes.each do |category, update_category|
          if update_category.respond_to?(:keys)
            updated_files = update_category.keys
          else
            begin
              updated_files = update_category.map { |file| file[:path] }
            rescue TypeError
              updated_files = update_category.to_a
            end
          end

          summary[category] = updated_files
        end

        summary
      end

      def print_summary
        require 'pdk/report'

        footer = false

        summary.keys.each do |category|
          next if summary[category].empty?

          PDK::Report.default_target.puts("\n%{banner}" % { banner: generate_banner("Files to be #{category}", 40) })
          PDK::Report.default_target.puts(summary[category])
          footer = true
        end

        PDK::Report.default_target.puts("\n%{banner}" % { banner: generate_banner('', 40) }) if footer
      end

      def print_result(banner_text)
        require 'pdk/report'

        PDK::Report.default_target.puts("\n%{banner}" % { banner: generate_banner(banner_text, 40) })
        summary_to_print = summary.map { |k, v| "#{v.length} files #{k}" unless v.empty? }.compact
        PDK::Report.default_target.puts("\n%{summary}\n\n" % { summary: "#{summary_to_print.join(', ')}." })
      end

      def full_report(path)
        require 'pdk/report'

        report = ["/* Report generated by PDK at #{Time.now} */"]
        report.concat(update_manager.changes[:modified].map { |_, diff| "\n\n\n#{diff}" })
        PDK::Util::Filesystem.write_file(path, report.join)
        PDK::Report.default_target.puts("\nYou can find a report of differences in %{path}.\n\n" % { path: path })
      end

      def generate_banner(text, width = 80)
        padding = width - text.length
        banner = ''
        padding_char = '-'

        (padding / 2.0).ceil.times { banner << padding_char }
        banner << text
        (padding / 2.0).floor.times { banner << padding_char }

        banner
      end
    end
  end
end
