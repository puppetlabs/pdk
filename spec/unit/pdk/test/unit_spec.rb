require 'spec_helper'
require 'pdk/tests/unit'

describe PDK::Test::Unit do
  it 'has an invoke method' do
    expect(described_class.methods(false)).to include(:invoke)
  end
end
