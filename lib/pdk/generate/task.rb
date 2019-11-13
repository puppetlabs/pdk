require 'pdk'

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
        @target_object_path ||= File.join(module_dir, 'tasks', "#{task_name}.sh")
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

        PDK::Util::Filesystem.glob(File.join(module_dir, 'tasks', "#{task_name}.*")).each do |file|
          next if allowed_extensions.include?(File.extname(file))

          raise PDK::CLI::ExitWithError, error % { name: task_name, file: file }
        end
      end

      # Writes the <module>/tasks/<task_name>.json metadata file for the task.
      #
      # @api private
      def write_task_metadata
        write_file(File.join(module_dir, 'tasks', "#{task_name}.json")) do
          task_metadata = template_data.dup
          task_metadata.delete(:name)
          JSON.pretty_generate(task_metadata)
        end
      end

      # Calculates the file name of the task files ('init' if the task has the
      # same name as the module, otherwise use the specified task name).
      #
      # @return [String] the base name of the file(s) for the task.
      #
      # @api private
      def task_name
        (object_name == module_name) ? 'init' : object_name
      end
    end
  end
end
