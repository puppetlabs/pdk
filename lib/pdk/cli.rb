require 'cri'

require 'pdk/cli/errors'
require 'pdk/cli/util'
require 'pdk/cli/util/option_normalizer'
require 'pdk/cli/util/option_validator'
require 'pdk/generators/module'
require 'pdk/i18n'
require 'pdk/logger'
require 'pdk/report'
require 'pdk/util/version'

module PDK::CLI
  def self.run(args)
    @base_cmd.run(args)
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
    dsl.option nil, 'template-url', _('Specifies the URL to the template to use when creating new modules, and other parts.'), argument: :required, default: PDK::Generate::Module::DEFAULT_TEMPLATE
  end

  @base_cmd = Cri::Command.define do
    name 'pdk'
    usage _('pdk command [options]')
    summary _('Puppet Development Kit')
    description _('The shortest path to better modules.')
    default_subcommand 'help'

    flag nil, :version, _('show version of pdk') do |_, _|
      puts PDK::Util::Version.version_string
      exit 0
    end

    flag :h, :help, _('show help for this command') do |_, c|
      puts c.help
      exit 0
    end

    format_desc = _(
      "Specify desired output format. Valid formats are '%{available_formats}'. " \
      'You may also specify a file to which the formatted output will be directed, ' \
      "for example: '--format=junit:report.xml'. This option may be specified " \
      'multiple times as long as each option specifies a distinct target file.',
    ) % { available_formats: PDK::Report.formats.join("', '") }

    option :f, :format, format_desc, argument: :required, multiple: true do |values|
      PDK::CLI::Util::OptionNormalizer.report_formats(values.compact)
    end

    flag :d, :debug, _('Enable debug output.') do |_, _|
      PDK.logger.enable_debug_output
    end

    option nil, 'answer-file', _('Path to an answer file'), argument: :required, hidden: true do |value|
      PDK.answer_file = value
    end
  end

  require 'pdk/cli/bundle'
  require 'pdk/cli/new'
  require 'pdk/cli/test'
  require 'pdk/cli/validate'

  @base_cmd.add_command Cri::Command.new_basic_help
end
