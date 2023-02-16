require 'pdk'

module PDK
  module Generate
    class Task < PuppetObject
      def friendly_name
        'Task'
      end

      def template_files
        return {} if spec_only?
        {
          'task.erb' => File.join('tasks', task_name + '.sh'),
        }
      end

      def template_data
        {
          name: object_name,
        }
      end

      # Checks that the task has not already been defined with a different
      # extension.
      #
      # @raise [PDK::CLI::ExitWithError] if files with the same name as the
      # task exist in the <module>/tasks/ directory
      def check_preconditions
        super

        error = "A task named '%{name}' already exists in this module; defined in %{file}"
        allowed_extensions = %w[.md .conf]

        PDK::Util::Filesystem.glob(File.join(context.root_path, 'tasks', task_name + '.*')).each do |file|
          next if allowed_extensions.include?(File.extname(file))

          raise PDK::CLI::ExitWithError, error % { name: task_name, file: file }
        end
      end

      def non_template_files
        task_metadata_file = File.join('tasks', task_name + '.json')
        { task_metadata_file => JSON.pretty_generate(task_metadata) }
      end

      private

      # Calculates the file name of the task files ('init' if the task has the
      # same name as the module, otherwise use the specified task name).
      #
      # @return [String] the base name of the file(s) for the task.
      #
      # @api private
      def task_name
        (object_name == module_name) ? 'init' : object_name
      end

      def task_metadata
        {
          puppet_task_version: 1,
          supports_noop:       false,
          description:         options.fetch(:description, 'A short description of this task'),
          parameters:          {},
        }
      end
    end
  end
end
