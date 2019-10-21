require 'spec_helper'
require 'pdk/generate/transport'

# rubocop:disable RSpec/EmptyExampleGroup
describe PDK::Generate::Transport do
  subject(:generator) { described_class.new(module_dir, given_name, options) }

  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:given_name) { 'test_transport' }

  # TODO: Write some tests!!
end
# rubocop:enable RSpec/EmptyExampleGroup
