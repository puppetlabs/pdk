require 'spec_helper'

describe PDK::CLI::New do
  context 'when no arguments or options are provided' do
    it do
      expect do
        PDK::CLI.run(['new'])
      end.to raise_error(SystemExit) { |error|
        expect(error.status).to be 1
      }.and output(/^USAGE\s+pdk new/m).to_stdout
    end
  end
end
