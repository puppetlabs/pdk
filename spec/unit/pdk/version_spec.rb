require 'spec_helper'
require 'pdk/version'

describe 'PDK version string', use_stubbed_analytics: false do
  it 'has major minor and patch numbers' do
    expect(PDK::VERSION).to match(/^[0-9]+\.[0-9]+\.[0-9]+/)
  end
end
