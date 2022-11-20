module PDK
  autoload :Analytics, 'pdk/analytics'
  autoload :AnswerFile, 'pdk/answer_file'
  autoload :Bolt, 'pdk/bolt'
  autoload :Config, 'pdk/config'
  autoload :Context, 'pdk/context'
  autoload :ControlRepo, 'pdk/control_repo'
  autoload :Generate, 'pdk/generate'
  autoload :Logger, 'pdk/logger'
  autoload :Module, 'pdk/module'
  autoload :Report, 'pdk/report'
  autoload :Template, 'pdk/template'
  autoload :TEMPLATE_REF, 'pdk/version'
  autoload :Util, 'pdk/util'
  autoload :Validate, 'pdk/validate'
  autoload :VERSION, 'pdk/version'

  # TODO: Refactor backend code to not raise CLI errors or use CLI util
  #       methods.
  module CLI
    autoload :ExitWithError, 'pdk/cli/errors'
    autoload :FatalError, 'pdk/cli/errors'
    autoload :Util, 'pdk/cli/util'
    autoload :Exec, 'pdk/cli/exec'
    autoload :ExecGroup, 'pdk/cli/exec_group'
  end

  module Test
    autoload :Unit, 'pdk/tests/unit'
  end

  def self.logger
    @logger ||= PDK::Logger.new
  end

  def self.config
    return @config unless @config.nil?
    options = {}
    options['user.module_defaults.path'] = PDK::Util::Env['PDK_ANSWER_FILE'] unless PDK::Util::Env['PDK_ANSWER_FILE'].nil?
    @config = PDK::Config.new(options)
  end

  def self.context
    @context ||= PDK::Context.create(Dir.pwd)
  end

  def self.available_feature_flags
    @available_feature_flags ||= %w[
      controlrepo
    ].freeze
  end

  def self.requested_feature_flags
    @requested_feature_flags ||= (PDK::Util::Env['PDK_FEATURE_FLAGS'] || '').split(',').map { |flag| flag.strip }
  end

  def self.feature_flag?(flagname)
    return false unless available_feature_flags.include?(flagname)
    requested_feature_flags.include?(flagname)
  end

  def self.analytics
    @analytics ||= PDK::Analytics.build_client(
      logger:        PDK.logger,
      disabled:      PDK::Util::Env['PDK_DISABLE_ANALYTICS'] || PDK.config.get_within_scopes('analytics.disabled', %w[user system]),
      user_id:       PDK.config.get_within_scopes('analytics.user-id', %w[user system]),
      app_id:        "UA-139917834-#{PDK::Util.development_mode? ? '2' : '1'}",
      client:        :google_analytics,
      app_name:      'pdk',
      app_version:   PDK::VERSION,
      app_installer: PDK::Util.package_install? ? 'package' : 'gem',
    )
  end
end
