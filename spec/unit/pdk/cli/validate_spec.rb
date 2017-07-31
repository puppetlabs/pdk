require 'spec_helper'

describe 'Running `pdk validate`' do
  subject(:validate_cmd) { PDK::CLI.instance_variable_get(:@validate_cmd) }

  it { is_expected.not_to be_nil }
end
