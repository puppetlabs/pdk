require 'spec_helper'
require 'pdk/generate/provider'

describe PDK::Generate::Provider do
  subject(:generator) { described_class.new(module_dir, given_name, options) }

  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:given_name) { 'test_provider' }

  # TODO Write some tests!!
end
