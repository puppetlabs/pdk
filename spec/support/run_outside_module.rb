RSpec.shared_context 'run outside module' do
  before(:each) do
    msg = 'must be run from inside a valid module (no metadata.json found)'
    allow(PDK::CLI::Util).to receive(:ensure_in_module!).with(any_args).and_raise(PDK::CLI::ExitWithError, msg)
  end
end
