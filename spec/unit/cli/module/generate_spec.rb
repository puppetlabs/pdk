require 'spec_helper'

describe 'Running pdk module generate' do
  subject { PDK::CLI.instance_variable_get(:@new_module_cmd) }

  let(:module_name) { 'foo' }

  describe 'when not passed a module name' do
    it do
      expect {
        PDK::CLI.run(%w[module generate])
      }.to raise_error(SystemExit) { |error|
        expect(error.status).to eq(1)
      }.and output(a_string_matching(%r{^USAGE\s+pdk module generate}m)).to_stdout
    end
  end

  context 'with a yes at the prompt' do
    before(:each) do
      redirector = instance_double('PDK::CLI::Util::CommandRedirector')
      allow(redirector).to receive(:target_command)
      allow(redirector).to receive(:run).and_return(true)
      expect(logger).to receive(:info).with(%r{New modules are created using the ‘pdk new module’ command}i)
      expect(PDK::CLI::Util::CommandRedirector).to receive(:new).and_return(redirector)
    end

    it 'to call to new module generator' do
      expect(logger).to receive(:info).with(%r{Creating new module:}i)
      expect(PDK::Generate::Module).to receive(:invoke)
      PDK::CLI.run(['module', 'generate', module_name])
    end
  end

  # context 'with a no at the prompt' do
  #  before(:each) do
  #    redirector = instance_double('PDK::CLI::Util::CommandRedirector')
  #    allow(redirector).to receive(:target_command)
  #    allow(redirector).to receive(:run).and_return(false)
  #    expect(logger).to receive(:info).with(%r{New modules are created using the ‘pdk new module’ command}i)
  #    expect(PDK::CLI::Util::CommandRedirector).to receive(:new).and_return(redirector)
  #  end

  #  it 'to not call new module generator' do
  #    expect(logger).not_to receive(:info).with(%r{Creating new module:}i)
  #    expect(PDK::Generate::Module).not_to receive(:invoke)
  #    PDK::CLI.run(['module', 'generate', module_name])
  #  end
  # end
end
