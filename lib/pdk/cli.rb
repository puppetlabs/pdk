require 'cri'

require 'pdk'
require 'pdk/cli/errors'

module TTY
  autoload :Prompt, 'tty/prompt'
  autoload :TestPrompt, 'tty/test_prompt'
end

class Cri::Command::CriExitException
  def initialize(is_error:)
    @is_error = is_error
    PDK.analytics.event('CLI', 'invalid command', label: PDK::CLI.anonymised_args.join(' ')) if error?
  end
end

module PDK::CLI
  autoload :Util, 'pdk/cli/util'

  # Attempt to anonymise the raw ARGV array if the command parsing failed.
  #
  # If an item does not start with '-' but is preceeded by an item that does
  # start with '-', assume that these items are an option/value pair and redact
  # the value. Any additional values that do not start with '-' that follow an
  # option/value pair are assumed to be arguments (rather than subcommand
  # names) and are also redacted.
  #
  # @example
  #   # Where PDK::CLI.args => ['new', 'plan', '--some', 'value', 'plan_name']
  #
  #   PDK::CLI.anonymised_args
  #     => ['new', 'plan', '--some', 'redacted', 'redacted']
  #
  # @return Array[String] the command arguments with any identifying values
  #   redacted.
  def self.anonymised_args
    in_args = false
    @args.map do |arg|
      if arg.start_with?('-')
        in_args = true
        arg
      else
        in_args ? 'redacted' : arg
      end
    end
  end

  def self.deprecated_runtime?
    Gem::Version.new(RbConfig::CONFIG['ruby_version']) < Gem::Version.new('2.4.0')
  end

  def self.run(args)
    if deprecated_runtime?
      PDK.logger.info(
        text: _(
          'Support for Ruby versions older than 2.4 will be dropped in the ' \
          'future PDK 2.0.0 release. We recommend updating your Ruby ' \
          'installation to ensure that you can continue using the latest ' \
          'version of PDK.',
        ),
        wrap: true,
      )
    end

    @args = args
    PDK::Config.analytics_config_interview! unless PDK::Util::Env['PDK_DISABLE_ANALYTICS'] || PDK::Config.analytics_config_exist?
    @base_cmd.run(args)
  rescue PDK::CLI::ExitWithError => e
    PDK.logger.send(e.log_level, e.message)

    exit e.exit_code
  rescue PDK::CLI::FatalError => e
    PDK.logger.fatal(e.message) if e.message

    # If FatalError was raised as the result of another exception, send the
    # details of that exception to the debug log. If there was no cause
    # (FatalError raised on its own outside a rescue block), send the details
    # of the FatalError exception to the debug log.
    cause = e.cause
    if cause.nil?
      e.backtrace.each { |line| PDK.logger.debug(line) }
    else
      PDK.logger.debug("#{cause.class}: #{cause.message}")
      cause.backtrace.each { |line| PDK.logger.debug(line) }
    end

    exit e.exit_code
  end

  def self.template_url_option(dsl)
    require 'pdk/util/template_uri'

    desc = _('Specifies the URL to the template to use when creating new modules or classes. (default: %{default_url})') % { default_url: PDK::Util::TemplateURI.default_template_uri }

    dsl.option nil, 'template-url', desc, argument: :required
  end

  def self.template_ref_option(dsl)
    dsl.option nil, 'template-ref', _('Specifies the template git branch or tag to use when creating new modules or classes.'), argument: :required
  end

  def self.skip_interview_option(dsl)
    dsl.option nil, 'skip-interview', _('When specified, skips interactive querying of metadata.')
  end

  def self.full_interview_option(dsl)
    dsl.option nil, 'full-interview', _('When specified, interactive querying of metadata will include all optional questions.')
  end

  def self.puppet_version_options(dsl)
    dsl.option nil, 'puppet-version', _('Puppet version to run tests or validations against.'), argument: :required
    dsl.option nil, 'pe-version', _('Puppet Enterprise version to run tests or validations against.'), argument: :required
  end

  def self.puppet_dev_option(dsl)
    dsl.option nil,
               'puppet-dev',
               _('When specified, PDK will validate or test against the current Puppet source from github.com. To use this option, you must have network access to https://github.com.')
  end

  @base_cmd = Cri::Command.define do
    name 'pdk'
    usage _('pdk command [options]')
    summary _('Puppet Development Kit')
    description _('The shortest path to better modules.')
    default_subcommand 'help'

    flag nil, :version, _('Show version of pdk.') do |_, _|
      puts PDK::Util::Version.version_string
      exit 0
    end

    flag :h, :help, _('Show help for this command.') do |_, c|
      puts c.help
      exit 0
    end

    format_desc = _(
      "Specify desired output format. Valid formats are '%{available_formats}'. " \
      'You may also specify a file to which the formatted output is sent, ' \
      "for example: '--format=junit:report.xml'. This option may be specified " \
      'multiple times if each option specifies a distinct target file.',
    ) % { available_formats: PDK::Report.formats.join("', '") }

    option :f, :format, format_desc, argument: :required, multiple: true do |values|
      PDK::CLI::Util::OptionNormalizer.report_formats(values.compact)
    end

    flag :d, :debug, _('Enable debug output.') do |_, _|
      PDK.logger.enable_debug_output
    end
  end

  require 'pdk/cli/bundle'
  require 'pdk/cli/build'
  require 'pdk/cli/config'
  require 'pdk/cli/convert'
  require 'pdk/cli/get'
  require 'pdk/cli/new'
  require 'pdk/cli/set'
  require 'pdk/cli/test'
  require 'pdk/cli/update'
  require 'pdk/cli/validate'
  require 'pdk/cli/module'
  require 'pdk/cli/console'
  require 'pdk/cli/release'

  @base_cmd.add_command Cri::Command.new_basic_help
end
