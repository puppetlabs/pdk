require 'pdk/analytics'
require 'pdk/answer_file'
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
      logger: PDK.logger,
    )
  end
end
