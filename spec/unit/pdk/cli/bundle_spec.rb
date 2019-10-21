require 'spec_helper'
require 'pdk/cli'

describe 'Running `pdk bundle`' do
  subject(:test_cmd) { PDK::CLI.instance_variable_get(:@bundle_cmd) }

  it { is_expected.not_to be_nil }
end
