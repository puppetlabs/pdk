require 'pdk/config/errors'
require 'pdk/config/json'
require 'pdk/config/namespace'
require 'pdk/config/validator'
require 'pdk/config/value'
require 'pdk/config/yaml'

module PDK
  def self.config
    @config ||= PDK::Config.new
  end

  class Config
    def user
      @user ||= PDK::Config::JSON.new('user', file: PDK::Config.user_config_path) do
        mount :module_defaults, PDK::Config::JSON.new(file: PDK.answers.answer_file_path)

        mount :analytics, PDK::Config::YAML.new(file: PDK::Config.analytics_config_path) do
          value :disabled do
            validate PDK::Config::Validator.boolean
            default_to { PDK::Config.bolt_analytics_config.fetch('disabled', true) }
          end

          value 'user-id' do
            validate PDK::Config::Validator.uuid
            default_to do
              require 'securerandom'

              PDK::Config.bolt_analytics_config.fetch('user-id', SecureRandom.uuid)
            end
          end
        end
      end
    end

    def self.bolt_analytics_config
      PDK::Config::YAML.new(file: File.expand_path('~/.puppetlabs/bolt/analytics.yaml'))
    end

    def self.analytics_config_path
      File.join(File.dirname(PDK::Util.configdir), 'puppetlabs', 'analytics.yml')
    end

    def self.user_config_path
      File.join(PDK::Util.configdir, 'user_config.json')
    end
  end
end
