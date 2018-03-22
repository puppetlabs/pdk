# frozen_string_literal: true

require 'spec_helper'
load File.expand_path(File.join(__FILE__, '..', '..', '..', '..', 'lib', 'pdk', 'version.rb'))

describe 'PDK version string' do
  it 'has major minor and patch numbers' do
    expect(PDK::VERSION).to match(%r{^[0-9]+\.[0-9]+\.[0-9]+})
  end
end
