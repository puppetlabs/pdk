require 'pdk/analytics'
require 'pdk/answer_file'
require 'pdk/config'
require 'pdk/generate'
require 'pdk/i18n'
require 'pdk/logger'
require 'pdk/report'
require 'pdk/template_file'
require 'pdk/validate'
require 'pdk/version'

module PDK
  def self.analytics
    @analytics ||= PDK::Analytics.build_client(
      logger:   PDK.logger,
      disabled: ENV['PDK_DISABLE_ANALYTICS'] || PDK.config.user['analytics']['disabled'],
      uuid:     PDK.config.user['analytics']['user-id'],
    )
  end
end
