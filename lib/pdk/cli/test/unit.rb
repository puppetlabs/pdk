module PDK::CLI
  @test_unit_cmd = @test_cmd.define_command do
    name 'unit'
    usage 'unit [options]'
    summary 'Run unit tests.'

    PDK::CLI.puppet_version_options(self)
    PDK::CLI.puppet_dev_option(self)
    flag nil, :list, 'List all available unit test files.'
    flag nil, :parallel, 'Run unit tests in parallel.'
    flag :v, :verbose, 'More verbose --list output. Displays a list of examples in each unit test file.'
    flag :c, 'clean-fixtures', 'Clean up downloaded fixtures after the test run.'

    option nil, :tests, 'Specify a comma-separated list of unit test files to run.', argument: :required, default: '' do |values|
      require 'pdk/cli/util/option_validator'
      PDK::CLI::Util::OptionValidator.comma_separated_list?(values)
    end

    # TODO
    # option nil, :runner_options, "options to pass through to the actual test-runner", argument: :required

    run do |opts, _args, _cmd|
      require 'pdk/tests/unit'
      require 'pdk/report'
      require 'pdk/util/bundler'

      PDK::CLI::Util.validate_puppet_version_opts(opts)

      PDK::CLI::Util.ensure_in_module!(
        message:   'Unit tests can only be run from inside a valid module directory.',
        log_level: :info,
      )

      PDK::CLI::Util.module_version_check

      PDK::CLI::Util.analytics_screen_view('test_unit', opts)

      # Ensure that the bundled gems are up to date and correct Ruby is activated before running or listing tests.
      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
      PDK::Util::RubyVersion.use(puppet_env[:ruby_version])

      opts.merge!(puppet_env[:gemset])

      PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

      report = nil

      if opts[:list]
        examples = PDK::Test::Unit.list(opts)

        if examples.empty?
          puts 'No unit test files with examples were found.'
        else
          puts 'Unit Test Files:'
          files = examples.map { |example| example[:file_path] }
          files.uniq.each do |file|
            puts file

            next unless opts[:verbose]

            file_examples = examples.select { |example| example[:file_path] == file }
            file_examples.each do |file_example|
              puts "\t%{id}\t%{description}" % { id: file_example[:id], description: file_example[:full_description] }
            end
          end
        end
      else
        report = PDK::Report.new
        report_formats = if opts[:format]
                           opts[:interactive] = false
                           PDK::CLI::Util::OptionNormalizer.report_formats(opts[:format])
                         else
                           opts[:interactive] = true
                           [{
                             method: PDK::Report.default_format,
                             target: PDK::Report.default_target,
                           }]
                         end

        exit_code = PDK::Test::Unit.invoke(report, opts)

        report_formats.each do |format|
          report.send(format[:method], format[:target])
        end

        exit exit_code
      end
    end
  end
end
