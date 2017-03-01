require 'pick'
require 'pick/cli/option_validator'
require 'thor'

module Pick
  module CLI
    class Base < Thor
      class_option :report_file
      class_option :report_format

      desc 'generate [template] [name]', 'generates a `template` thing named `name`.'
      method_option :source, default: 'git@github.com:puppetlabs/modulesync_configs.git', desc: 'The source repository to load templates from.'

      def generate(template = 'module', name = 'example')
        puts "Generating a #{template} named '#{name}' ..."
        Pick::Generate.generate(template, name, options)
        puts "Generation done. Enjoy your new #{template}!"
      end

      desc 'validate [--list] [--validations=test_list] [--report-file=file_name] [--report-format=format]', 'Runs all static validations.'
      method_option :list, type: :boolean
      method_option :validators

      def validate
        validators = Pick::Validate.validators
        report = nil

        if options[:list]
          Pick::Validate.validators.each { |v| puts v.cmd }
          return
        end

        if options[:validators]
          # Ensure the argument is a comma separated list and that each validator exists
          vals = OptionValidator.list(options[:validators])
          OptionValidator.enum(vals, Pick::Validate.validators.map(&:cmd))
          validators = Pick::Validate.validators.find_all { |v| vals.include?(v.cmd) }
        end

        # Note: Reporting may be delegated to the validation tool itself.
        if options[:report_file]
          format = options[:report_format] || Pick::Report.default_format
          Pick::CLI::OptionValidator.enum(format, Pick::Report.formats)
          report = Report.new(options[:report_file], format)
        end

        validators.each do |validator|
          validator.invoke(report)
        end
      end
    end
  end
end
