require 'pdk/generate/defined_type'
require 'pdk/generate/module'
require 'pdk/generate/provider'
require 'pdk/generate/puppet_class'
require 'pdk/generate/task'
require 'pdk/generate/transport'

module PDK
  module Generate
    GENERATORS = [
      PDK::Generate::DefinedType,
      PDK::Generate::Provider,
      PDK::Generate::PuppetClass,
      PDK::Generate::Task,
      PDK::Generate::Transport,
    ].freeze
  end
end
