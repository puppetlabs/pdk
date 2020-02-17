require 'spec_helper'
require 'pdk/context'

describe PDK::Context::None do
  subject(:context) { described_class.new(nil) }

  it 'subclasses PDK::Context::AbstractContext' do
    expect(context).is_a?(PDK::Context::AbstractContext)
  end

  it 'has no parent context' do
    expect(context.parent_context).to be_nil
  end
end
