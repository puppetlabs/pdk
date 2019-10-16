require 'spec_helper'
require 'pdk/cli/util/command_redirector'

describe PDK::CLI::Util::CommandRedirector do
  subject(:command_redirector) do
    described_class.new(prompt, {})
  end

  let(:prompt) { instance_double('TTY::Prompt') }

  let(:command) { 'foo' }

  it 'initially has no target command' do
    expect(command_redirector.command).to eq(nil)
  end

  it 'sets the target' do
    command_redirector.target_command(command)
    expect(command_redirector.command).to eq(command)
  end

  it 'prints a query when run' do
    command_redirector.target_command('foo')
    expect(prompt).to receive(:puts).with(a_string_matching(%r{Did you mean.*foo.*?}i))
    expect(prompt).to receive(:yes?).with('-->')
    command_redirector.run
  end
end
