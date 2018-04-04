require 'spec_helper'

describe 'Running `pdk git`' do
  subject { PDK::CLI.instance_variable_get(:@git_cmd) }

  let(:result) do
    {
      stdout: 'stdout',
      stderr: 'stderr',
      exit_code: 1,
      duration: 10,
    }
  end

  context 'without arguments' do
    it 'runs git' do
      expect(PDK::CLI::Exec).to receive(:git).with(no_args).and_return(result)
      expect { PDK::CLI.run(['git']) }.not_to raise_error
    end
  end

  context 'with arguments' do
    it 'runs git' do
      expect(PDK::CLI::Exec).to receive(:git).with('foor', '--bar').and_return(result)
      expect { PDK::CLI.run(['git', 'foor', '--bar']) }.not_to raise_error
    end

    it 'outputs the commands results' do
      expect(PDK::CLI::Exec).to receive(:git).and_return(result)
      expect($stderr).to receive(:puts).with('stdoutstderr')

      expect { PDK::CLI.run(['git']) }.not_to raise_error
    end
  end
end
