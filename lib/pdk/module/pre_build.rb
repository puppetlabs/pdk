require 'pdk'

module PDK
  module Module
    module PreBuild
      module_function

      def run_validations(opts)
        PDK::CLI::Util.validate_puppet_version_opts(opts)

        PDK::CLI::Util.module_version_check

        puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
        PDK::Util::PuppetVersion.fetch_puppet_dev if opts[:'puppet-dev']
        PDK::Util::RubyVersion.use(puppet_env[:ruby_version])

        PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

        validator_exit_code, report = PDK::Validate.invoke_validators_by_name(PDK.context, PDK::Validate.validator_names, false, opts)
        report_formats = if opts[:format]
                           PDK::CLI::Util::OptionNormalizer.report_formats(opts[:format])
                         else
                           [{
                             method: PDK::Report.default_format,
                             target: PDK::Report.default_target
                           }]
                         end

        report_formats.each do |format|
          report.send(format[:method], format[:target])
        end

        raise PDK::CLI::ExitWithError, 'An error occured during validation' unless validator_exit_code.zero?
      end

      def run_documentation
        PDK.logger.info 'Updating documentation using puppet strings'
        docs_command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, 'exec', 'puppet', 'strings', 'generate', '--format', 'markdown', '--out', 'REFERENCE.md')
        docs_command.context = :module
        result = docs_command.execute!

        raise PDK::CLI::ExitWithError, format('An error occured generating the module documentation: %{stdout}', stdout: result[:stdout]) unless result[:exit_code].zero?
      end
    end
  end
end
