require 'spec_helper'
require 'stringio'

describe PDK::CLI::New do
  context 'when no arguments or options are provided' do
    it 'should display the help text for the "new" subcommand' do
      exit_status = nil

      expect do
        begin
          PDK::CLI.run(['new'])
        rescue SystemExit => e
          exit_status = e.status
        end
      end.to output(/^USAGE\s+pdk new/m).to_stdout

      expect(exit_status).to eq(1)
    end
  end
end
