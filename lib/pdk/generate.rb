require 'pdk'

module PDK
  module Generate
    autoload :DefinedType, 'pdk/generate/defined_type'
    autoload :Module, 'pdk/generate/module'
    autoload :Provider, 'pdk/generate/provider'
    autoload :PuppetClass, 'pdk/generate/puppet_class'
    autoload :PuppetObject, 'pdk/generate/puppet_object'
    autoload :Task, 'pdk/generate/task'
    autoload :Transport, 'pdk/generate/transport'

    def generators
      @generators ||= [
        PDK::Generate::DefinedType,
        PDK::Generate::Provider,
        PDK::Generate::PuppetClass,
        PDK::Generate::Task,
        PDK::Generate::Transport,
      ].freeze
    end
    module_function :generators
  end
end
