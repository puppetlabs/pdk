require 'spec_helper'
require 'pdk/cli/util'

describe 'PDK::CLI::Util' do
  context 'ensure_in_module! method' do
    subject(:ensure_in_module) { PDK::CLI::Util.ensure_in_module! }

    it 'raises an error when not in a module directory' do
      expect { ensure_in_module }.to raise_error(PDK::CLI::FatalError)
    end
  end
end
