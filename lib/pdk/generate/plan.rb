require 'pdk/generate/puppet_object'

module PDK
  module Generate
    class Plan < PuppetObject
      OBJECT_TYPE = :plan

      # Prepares the data needed to render the new plan template.
      #
      # @return [Hash{Symbol => Object}] a hash of information that will be
      # provided to the plan template during rendering. Additionally, this hash
      # (with the :name key removed) makes up the plan metadata.
      def template_data
        {
          name:                object_name,
          puppet_plan_version: 1,
          supports_noop:       false,
          description:         options.fetch(:description, 'A short description of this plan'),
          parameters:          {},
        }
      end

      # Calculates the path to the file where the new plan will be written.
      #
      # @return [String] the path to the plan file.
      def target_object_path
        @target_object_path ||= File.join(module_dir, 'plans', "#{plan_name}.pp")
      end

      # Calculates the path to the file where the tests for the new plan will
      # be written.
      #
      # @return [nil] as there is currently no test framework for plans.
      def target_spec_path
        nil
      end

      def run
        check_if_plan_already_exists

        super

        #write_plan_metadata
      end

      # Checks that the plan has not already been defined with a different
      # extension.
      #
      # @raise [PDK::CLI::ExitWithError] if files with the same name as the
      # plan exist in the <module>/plans/ directory
      #
      # @api private
      def check_if_plan_already_exists
        error = _("A plan named '%{name}' already exists in this module; defined in %{file}")
        allowed_extensions = %w[.md .conf]

        Dir.glob(File.join(module_dir, 'plans', "#{plan_name}.*")).each do |file|
          next if allowed_extensions.include?(File.extname(file))

          raise PDK::CLI::ExitWithError, error % { name: plan_name, file: file }
        end
      end

      # Writes the <module>/plans/<plan_name>.json metadata file for the plan.
      #
      # @api private
      def write_plan_metadata
        write_file(File.join(module_dir, 'plans', "#{plan_name}.json")) do
          plan_metadata = template_data.dup
          plan_metadata.delete(:name)
          JSON.pretty_generate(plan_metadata)
        end
      end

      # Calculates the file name of the plan files ('init' if the plan has the
      # same name as the module, otherwise use the specified plan name).
      #
      # @return [String] the base name of the file(s) for the plan.
      #
      # @api private
      def plan_name
        (object_name == module_name) ? 'init' : object_name
      end
    end
  end
end
