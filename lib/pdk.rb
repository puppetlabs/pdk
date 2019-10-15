require 'pdk/i18n'
require 'pdk/logger'

module PDK
  autoload :Analytics, 'pdk/analytics'
  autoload :AnswerFile, 'pdk/answer_file'
  autoload :Config, 'pdk/config'
  autoload :Generate, 'pdk/generate'
  autoload :Report, 'pdk/report'
  autoload :TEMPLATE_REF, 'pdk/version'
  autoload :Util, 'pdk/util'
  autoload :Validate, 'pdk/validate'
  autoload :VERSION, 'pdk/version'

  # TODO - Refactor backend code to not raise CLI errors
  module CLI
    autoload :FatalError, 'pdk/cli/errors'
    autoload :ExitWithError, 'pdk/cli/errors'
  end
end
