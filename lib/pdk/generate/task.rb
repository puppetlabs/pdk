require 'pdk/generate/puppet_object'

module PDK
  module Generate
    class Task < PuppetObject
      OBJECT_TYPE = :task

      # Prepares the data needed to render the new task template.
      #
      # @return [Hash{Symbol => Object}] a hash of information that will be
      # provided to the task template during rendering. Additionally, this hash
      # (with the :name key removed) makes up the task metadata.
      def template_data
        {
          name:                object_name,
          puppet_task_version: 1,
          supports_noop:       false,
          description:         options.fetch(:description, 'A short description of this task'),
          parameters:          {},
        }
      end

      # Calculates the path to the file where the new task will be written.
      #
      # @return [String] the path to the task file.
      def target_object_path
        "#{target_object_path_no_ext}.sh"
      end

      # Calculates the path to the file where the tests for the new task will
      # be written.
      #
      # @return [nil] as there is currently no test framework for Tasks.
      def target_spec_path
        nil
      end

      def run
        check_if_task_already_exists

        super

        write_task_metadata
      end

      # Checks that the task has not already been defined with a different
      # extension.
      #
      # @raise [PDK::CLI::ExitWithError] if files with the same name as the
      # task exist in the <module>/tasks/ directory
      #
      # @api private
      def check_if_task_already_exists
        error = _("A task named '%{name}' already exists in this module; defined in %{file}")
        allowed_extensions = %w[.md .conf]

        Dir.glob("#{target_object_path_no_ext}.*").each do |file|
          next if allowed_extensions.include?(File.extname(file))

          raise PDK::CLI::ExitWithError, error % { name: object_name, file: file }
        end
      end

      # Writes the <module>/tasks/<task_name>.json metadata file for the task.
      #
      # @api private
      def write_task_metadata
        write_file("#{target_object_path_no_ext}.json") do
          task_metadata = template_data.dup
          task_metadata.delete(:name)
          JSON.pretty_generate(task_metadata)
        end
      end

      # Calculates the path to the file where the new task will be written.
      #
      # @return [String] the path to the task file.
      def target_object_path_no_ext
        @target_object_path_no_ext ||= begin
          name_parts = object_name.split('::')[1..-1]
          name_parts << 'init' if name_parts.empty?

          File.join(module_dir, 'tasks', *name_parts)
        end
      end
    end
  end
end
