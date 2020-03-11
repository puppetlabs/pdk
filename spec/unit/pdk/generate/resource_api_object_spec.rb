require 'spec_helper'
require 'pdk/generate/resource_api_object'

# rubocop:disable RSpec/EmptyExampleGroup
describe PDK::Generate::ResourceAPIObject do
  subject(:generator) { described_class.new(context, given_name, options) }

  let(:context) { PDK::Context::Module.new(module_dir, module_dir) }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:given_name) { 'spec' }

  # TODO: Write some tests!!
end
# rubocop:enable RSpec/EmptyExampleGroup
