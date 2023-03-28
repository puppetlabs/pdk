RSpec.shared_context 'run outside module' do
  let(:mock_context) { PDK::Context::None.new(nil) }

  before do
    msg = 'must be run from inside a valid module (no metadata.json found)'
    allow(PDK::CLI::Util).to receive(:ensure_in_module!).with(any_args).and_raise(PDK::CLI::ExitWithError, msg)
    allow(PDK).to receive(:context).and_return(mock_context)
  end
end
