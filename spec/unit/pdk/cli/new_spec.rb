require 'spec_helper'
require 'pdk/cli'

describe 'Running `pdk new`' do
  subject { PDK::CLI.instance_variable_get(:@new_cmd) }

  context 'when no arguments or options are provided' do
    it do
      expect do
        PDK::CLI.run(['new'])
      end.to output(/^USAGE\s+pdk new/m).to_stdout
    end
  end
end
